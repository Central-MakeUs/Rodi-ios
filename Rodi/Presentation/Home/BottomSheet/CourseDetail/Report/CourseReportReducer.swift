import Foundation

struct CourseReportReducer: Reducer {
    enum FormState: Equatable {
        case loading, failed, loaded(CourseReportForm)
    }

    struct State {
        var courseID: Int64?
        var formState: FormState = .loading
        var selectedCodes: Set<String> = []
        var detail = ""
        var isSubmitting = false
        var isCompletionPresented = false
        var revision = UUID()

        var otherOption: CourseReportForm.Option? {
            guard selectedCodes.contains("OTHER"), case .loaded(let form) = formState else { return nil }
            return form.options.first(where: \.requiresTextInput)
        }

        var detailLimit: Int { min(otherOption?.textInputMaxLength ?? 30, 30) }

        var submission: CourseReportSubmission? {
            guard case .loaded(let form) = formState else { return nil }
            let codes = form.options.map(\.code).filter(selectedCodes.contains)
            guard !codes.isEmpty else { return nil }
            let reason = otherOption == nil ? nil : detail.normalizedOptionalText
            guard otherOption == nil || (reason != nil && detail.count <= detailLimit) else { return nil }
            return .init(issueCodes: codes, detail: reason)
        }
    }

    enum Action {
        case start(courseID: Int64)
        case retryTapped
        case formLoaded(Result<CourseReportForm, NetworkError>, courseID: Int64, revision: UUID)
        case optionToggled(String)
        case detailChanged(String)
        case submitTapped
        case submitted(Result<Void, NetworkError>, courseID: Int64, revision: UUID)
        case backTapped
        case completionConfirmed
        case reset
        case delegate(Delegate)
    }

    enum Delegate { case requestAuthentication, showSnackbar(String) }
    private enum EffectID { case workflow }

    let repository: CourseRepository
    let hasActiveSession: () -> Bool

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let courseID):
            guard state.courseID == nil else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state = .init(courseID: courseID)
            return loadForm(courseID: courseID, revision: state.revision)

        case .retryTapped:
            guard let courseID = state.courseID, state.formState == .failed else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state.formState = .loading
            state.revision = UUID()
            return loadForm(courseID: courseID, revision: state.revision)

        case let .formLoaded(result, courseID, revision):
            guard state.courseID == courseID, state.revision == revision, state.formState == .loading else { return .none }
            switch result {
            case .success(let form): state.formState = .loaded(form)
            case .failure(let error):
                state.formState = .failed
                if needsAuthentication(error) { return .send(.delegate(.requestAuthentication)) }
            }

        case .optionToggled(let code):
            guard !state.isSubmitting, !state.isCompletionPresented, case .loaded(let form) = state.formState,
                  form.options.contains(where: { $0.code == code }) else { return .none }
            if state.selectedCodes.remove(code) == nil { state.selectedCodes.insert(code) }
            if state.otherOption == nil { state.detail = "" }

        case .detailChanged(let detail):
            guard !state.isSubmitting, !state.isCompletionPresented, state.otherOption != nil,
                  detail.count <= state.detailLimit else { return .none }
            state.detail = detail

        case .submitTapped:
            guard let courseID = state.courseID, let submission = state.submission,
                  !state.isSubmitting, !state.isCompletionPresented else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state.isSubmitting = true
            state.revision = UUID()
            return submit(submission, courseID: courseID, revision: state.revision)

        case let .submitted(result, courseID, revision):
            guard state.courseID == courseID, state.revision == revision, state.isSubmitting else { return .none }
            state.isSubmitting = false
            switch result {
            case .success:
                state.isCompletionPresented = true
            case .failure(let error):
                if needsAuthentication(error) { return .send(.delegate(.requestAuthentication)) }
                if case .apiError(code: "COURSE_400_1", message: _, httpStatusCode: _) = error {
                    return .send(.delegate(.showSnackbar("직접 등록한 코스는 신고할 수 없어요.")))
                }
                return .send(.delegate(.showSnackbar("코스를 신고하지 못했어요. 다시 시도해주세요.")))
            }

        case .backTapped:
            guard !state.isSubmitting, !state.isCompletionPresented else { return .none }
            return reduce(&state, with: .reset)
        case .completionConfirmed:
            guard state.isCompletionPresented else { return .none }
            return reduce(&state, with: .reset)
        case .reset:
            state = .init()
            return .cancel(id: EffectID.workflow)
        case .delegate:
            break
        }
        return .none
    }
}

private extension CourseReportReducer {
    func loadForm(courseID: Int64, revision: UUID) -> Effect<Action> {
        .run { [repository] send in
            let result: Result<CourseReportForm, NetworkError>
            do throws(NetworkError) { result = .success(try await repository.fetchReportForm()) }
            catch { result = .failure(error) }
            guard !Task.isCancelled else { return }
            await send(.formLoaded(result, courseID: courseID, revision: revision))
        }.cancelTask(id: EffectID.workflow)
    }

    func submit(_ submission: CourseReportSubmission, courseID: Int64, revision: UUID) -> Effect<Action> {
        .run { [repository] send in
            let result: Result<Void, NetworkError>
            do throws(NetworkError) {
                try await repository.report(courseID: courseID, submission: submission)
                result = .success(())
            } catch { result = .failure(error) }
            guard !Task.isCancelled else { return }
            await send(.submitted(result, courseID: courseID, revision: revision))
        }.cancelTask(id: EffectID.workflow)
    }

    func needsAuthentication(_ error: NetworkError) -> Bool {
        switch error {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }
}
