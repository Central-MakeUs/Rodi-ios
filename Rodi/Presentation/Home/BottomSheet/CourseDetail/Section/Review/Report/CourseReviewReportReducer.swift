import Foundation

struct CourseReviewReportReducer: Reducer {
    enum FormResult { case success(ReviewReportForm), failure(String) }
    enum SubmissionResult { case success, failure(String) }
    enum FormState: Equatable { case idle, loading, loaded(ReviewReportForm), failed }

    struct State: Equatable {
        var reviewID: Int?
        var formState: FormState = .idle
        var selectedOption: ReviewReportOption?
        var detail = ""
        var isSubmitting = false
        var isCompletionPresented = false
        var revision = UUID()

        var canSubmit: Bool {
            guard let selectedOption else { return false }
            return !selectedOption.requiresTextInput || !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var maximumLength: Int? {
            guard let selectedOption, selectedOption.requiresTextInput else { return nil }
            return min(selectedOption.textInputMaxLength ?? 100, 100)
        }
    }

    enum Action {
        case start(reviewID: Int)
        case retryTapped
        case formLoaded(FormResult, reviewID: Int, revision: UUID)
        case optionSelected(ReviewReportOption)
        case detailChanged(String)
        case submitTapped
        case submissionCompleted(SubmissionResult, reviewID: Int, revision: UUID)
        case completionConfirmed
        case backTapped
        case reset
        case delegate(Delegate)
    }

    enum Delegate { case submitted(reviewID: Int), dismissed, requestAuthentication, showSnackbar(String) }
    private enum EffectID: Hashable { case workflow }

    private let repository: ReviewRepository
    private let hasActiveSession: () -> Bool

    init(repository: ReviewRepository, hasActiveSession: @escaping () -> Bool) {
        self.repository = repository
        self.hasActiveSession = hasActiveSession
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let reviewID):
            state = .init(reviewID: reviewID, formState: .loading)
            return fetchForm(reviewID: reviewID, revision: state.revision)
        case .retryTapped:
            guard let reviewID = state.reviewID, state.formState != .loading else { return .none }
            state.formState = .loading; state.revision = UUID()
            return fetchForm(reviewID: reviewID, revision: state.revision)
        case let .formLoaded(result, reviewID, revision):
            guard state.reviewID == reviewID, state.revision == revision else { return .none }
            switch result {
            case .success(let form): state.formState = .loaded(form)
            case .failure(let message): state.formState = .failed; return .send(.delegate(.showSnackbar(message)))
            }
        case .optionSelected(let option):
            guard case .loaded(let form) = state.formState, form.options.contains(where: { $0.code == option.code }) else { return .none }
            state.selectedOption = option
            if !option.requiresTextInput { state.detail = "" }
        case .detailChanged(let value):
            guard let maximumLength = state.maximumLength, value.count <= maximumLength else { return .none }
            state.detail = value
        case .submitTapped:
            guard let reviewID = state.reviewID, let option = state.selectedOption, state.canSubmit, !state.isSubmitting else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state.isSubmitting = true; state.revision = UUID()
            let detail = option.requiresTextInput ? state.detail.trimmingCharacters(in: .whitespacesAndNewlines) : nil
            return submit(reviewID: reviewID, submission: .init(reasonCode: option.code, detail: detail), revision: state.revision)
        case let .submissionCompleted(result, reviewID, revision):
            guard state.reviewID == reviewID, state.revision == revision, state.isSubmitting else { return .none }
            state.isSubmitting = false
            switch result {
            case .success: state.isCompletionPresented = true
            case .failure(let message): return .send(.delegate(.showSnackbar(message)))
            }
        case .completionConfirmed:
            guard let reviewID = state.reviewID, state.isCompletionPresented else { return .none }
            return .send(.delegate(.submitted(reviewID: reviewID)))
        case .backTapped: return .send(.delegate(.dismissed))
        case .reset:
            state = .init(); return .cancel(id: EffectID.workflow)
        case .delegate: return .none
        }
        return .none
    }
}

private extension CourseReviewReportReducer {
    func fetchForm(reviewID: Int, revision: UUID) -> Effect<Action> {
        let repository = repository
        return .run { send in
            do { await send(.formLoaded(.success(try await repository.fetchReportForm()), reviewID: reviewID, revision: revision)) }
            catch is CancellationError { }
            catch let error as NetworkError {
                if requiresAuthentication(error) { await send(.delegate(.requestAuthentication)) }
                await send(.formLoaded(.failure("신고 사유를 불러오지 못했어요. 다시 시도해주세요."), reviewID: reviewID, revision: revision))
            } catch { await send(.formLoaded(.failure("신고 사유를 불러오지 못했어요. 다시 시도해주세요."), reviewID: reviewID, revision: revision)) }
        }.cancelTask(id: EffectID.workflow)
    }
    func submit(reviewID: Int, submission: ReviewReportSubmission, revision: UUID) -> Effect<Action> {
        let repository = repository
        return .run { send in
            do { try await repository.report(reviewID: reviewID, submission: submission); await send(.submissionCompleted(.success, reviewID: reviewID, revision: revision)) }
            catch is CancellationError { }
            catch let error as NetworkError {
                if requiresAuthentication(error) { await send(.delegate(.requestAuthentication)) }
                await send(.submissionCompleted(.failure(error.localizedDescription), reviewID: reviewID, revision: revision))
            } catch { await send(.submissionCompleted(.failure("후기를 신고하지 못했어요. 다시 시도해주세요."), reviewID: reviewID, revision: revision)) }
        }.cancelTask(id: EffectID.workflow)
    }
    func requiresAuthentication(_ error: NetworkError) -> Bool {
        switch error { case .refreshFailGoRoot, .httpStatusCode(401): true; case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"; default: false }
    }
}
