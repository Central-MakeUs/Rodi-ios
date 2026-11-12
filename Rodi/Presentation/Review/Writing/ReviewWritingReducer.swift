import Foundation

struct ReviewWritingReducer: Reducer {
    struct State {
        enum Page: Equatable {
            case hidden
            case loading
            case loadFailed(String)
            case first
            case second
        }

        enum Mode: Equatable {
            case create
            case edit(reviewID: Int)
        }

        var page: Page = .hidden
        var mode: Mode = .create
        var target: ReviewWriteRequest?
        var form: ReviewWritingForm?
        var draft = ReviewDraft()
        var isSubmitting = false
        var isDiscardConfirmationPresented = false
        var isCompletionPresented = false
        var isCompletionDismissing = false
        var flowID = UUID()
        var requestID = 0

        var canProceedToSecondPage: Bool {
            draft.canProceedToSecondPage(form: form)
        }

        var canSubmit: Bool {
            !isSubmitting && draft.submission(form: form) != nil
        }

        var issueTextOption: ReviewWritingForm.Option? { draft.issueTextOption(in: form) }
        var contentLimit: Int { min(form?[.content]?.maxLength ?? 150, 150) }
    }

    struct LoadedForm {
        let target: ReviewWriteRequest
        let form: ReviewWritingForm?
        let detail: ReviewDetail?
    }

    enum Action {
        case start(ReviewWriteRequest)
        case editStarted(reviewID: Int)
        case formLoaded(ReviewRequestResult<LoadedForm>, flowID: UUID, requestID: Int)
        case retryLoading
        case recommendationSelected(Bool)
        case difficultySelected(ReviewDifficulty)
        case congestionSelected(ReviewCongestion)
        case cautionChanged(String)
        case courseIssueToggled(String)
        case courseIssueDetailChanged(String)
        case nextTapped
        case backTapped
        case practiceMethodSelected(ReviewPracticeMethod)
        case contentChanged(String)
        case closeTapped
        case discardConfirmed
        case discardCancelled
        case submitTapped
        case submissionCompleted(ReviewRequestResult<Void>, flowID: UUID, requestID: Int)
        case completionConfirmed
        case completionRefreshFinished(flowID: UUID)
        case reset
        case cancelLoading
        case cancelSubmission
        case delegate(Delegate)
    }

    enum Delegate {
        case finished
        case completionRefreshRequested(ReviewWriteRequest, flowID: UUID)
        case editingFailed(String)
        case showSnackbar(String)
    }

    private enum EffectID {
        case loading
        case submission
        case completionDismissal
    }

    private let service: any ReviewWritingServicing
    private let tracksAnalytics: Bool

    init(service: any ReviewWritingServicing, tracksAnalytics: Bool = true) {
        self.service = service
        self.tracksAnalytics = tracksAnalytics
    }
}

// MARK: - Reduce
extension ReviewWritingReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let request):
            state = .init(page: service.usesServerForm ? .loading : .first,
                          mode: .create, target: request, requestID: state.requestID + 1)
            if tracksAnalytics { RodiAnalytics.track(.reviewWritingOpened(mode: "create")) }
            if service.usesServerForm { return loadEffect(state: state) }

        case .editStarted(let reviewID):
            state = .init(page: .loading, mode: .edit(reviewID: reviewID), requestID: state.requestID + 1)
            if tracksAnalytics { RodiAnalytics.track(.reviewWritingOpened(mode: "edit")) }
            return loadEffect(state: state)

        case .retryLoading:
            guard case .loadFailed = state.page else { return .none }
            state.page = .loading
            state.requestID += 1
            return loadEffect(state: state)

        case .formLoaded(let result, let flowID, let requestID):
            guard state.page == .loading,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }

            switch result {
            case .success(let loaded):
                state.target = loaded.target
                state.form = loaded.form
                if let detail = loaded.detail { state.draft = .init(detail: detail) }
                state.page = .first
            case .failure(let message):
                if !service.usesServerForm { return .send(.delegate(.editingFailed(message))) }
                state.page = .loadFailed(message)
            }

        case .recommendationSelected(let value):
            guard state.page == .first else { return .none }
            if state.form != nil, state.draft.isRecommended != value {
                if value {
                    state.draft.courseIssues = []
                    state.draft.courseIssueDetail = ""
                } else {
                    state.draft.difficulty = nil
                    state.draft.congestion = nil
                    state.draft.caution = ""
                }
            }
            state.draft.isRecommended = value

        case .difficultySelected(let value):
            guard state.page == .first else { return .none }
            state.draft.difficulty = value

        case .congestionSelected(let value):
            guard state.page == .first else { return .none }
            state.draft.congestion = value

        case .cautionChanged(let value):
            guard state.page == .first,
                  state.form?[.caution]?.maxLength.map({ value.count <= $0 }) ?? true else { return .none }
            state.draft.caution = value

        case .courseIssueToggled(let code):
            guard state.page == .first, state.draft.isRecommended == false,
                  state.form?[.courseIssues]?.options.contains(where: { $0.code == code }) == true else { return .none }
            if state.draft.courseIssues.remove(code) == nil { state.draft.courseIssues.insert(code) }
            if state.issueTextOption == nil { state.draft.courseIssueDetail = "" }

        case .courseIssueDetailChanged(let value):
            guard state.page == .first, let option = state.issueTextOption,
                  value.count <= min(option.textInputMaxLength ?? 30, 30) else { return .none }
            state.draft.courseIssueDetail = value

        case .nextTapped:
            guard state.page == .first, state.canProceedToSecondPage else { return .none }
            state.page = .second

        case .backTapped:
            guard state.page == .second, !state.isSubmitting else { return .none }
            state.page = .first

        case .practiceMethodSelected(let value):
            guard state.page == .second else { return .none }
            state.draft.practiceMethod = value

        case .contentChanged(let value):
            guard state.page == .second, value.count <= state.contentLimit else { return .none }
            state.draft.content = value

        case .closeTapped:
            guard state.page != .hidden,
                  !state.isSubmitting,
                  !state.isCompletionPresented
            else {
                return .none
            }
            state.isDiscardConfirmationPresented = true

        case .discardConfirmed:
            guard state.isDiscardConfirmationPresented else { return .none }
            state.requestID += 1
            return .run { send in
                await send(.cancelLoading)
                await send(.delegate(.finished))
            }

        case .discardCancelled:
            state.isDiscardConfirmationPresented = false

        case .submitTapped:
            guard state.page == .second,
                  state.canSubmit,
                  let target = state.target,
                  let submission = state.draft.submission(form: state.form)
            else {
                return .none
            }
            state.isSubmitting = true
            state.requestID += 1
            if tracksAnalytics {
                RodiAnalytics.track(
                    .reviewSubmitted(
                        mode: state.mode.analyticsName,
                        hasContent: submission.content != nil
                    )
                )
            }
            return submitEffect(
                mode: state.mode,
                placeID: target.placeID,
                submission: submission,
                flowID: state.flowID,
                requestID: state.requestID
            )

        case .submissionCompleted(let result, let flowID, let requestID):
            guard state.page == .second,
                  state.isSubmitting,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }
            state.isSubmitting = false
            switch result {
            case .success:
                state.isCompletionPresented = true
                if tracksAnalytics { RodiAnalytics.track(.reviewCompleted(mode: state.mode.analyticsName)) }
            case .failure(let message):
                if tracksAnalytics { RodiAnalytics.track(.reviewSubmissionFailed(mode: state.mode.analyticsName)) }
                return .send(.delegate(.showSnackbar(message)))
            }

        case .completionConfirmed:
            guard state.isCompletionPresented,
                  !state.isCompletionDismissing,
                  let target = state.target
            else {
                return .none
            }
            state.isCompletionDismissing = true
            return .send(.delegate(.completionRefreshRequested(target, flowID: state.flowID)))

        case .completionRefreshFinished(let flowID):
            guard state.isCompletionDismissing,
                  state.flowID == flowID
            else {
                return .none
            }
            state.isCompletionPresented = false
            state.isCompletionDismissing = false
            return .send(.delegate(.finished))

        case .reset:
            state = .init()
            return .run { send in
                await send(.cancelLoading)
                await send(.cancelSubmission)
            }

        case .cancelLoading:
            return .cancel(id: EffectID.loading)

        case .cancelSubmission:
            return .cancel(id: EffectID.submission)

        case .delegate:
            return .none
        }

        return .none
    }
}

private extension ReviewWritingReducer.State.Mode {
    var analyticsName: String {
        switch self {
        case .create: "create"
        case .edit: "edit"
        }
    }
}

// MARK: - Effect
private extension ReviewWritingReducer {

    func loadEffect(state: State) -> Effect<Action> {
        let service = service
        let (mode, initialTarget, flowID, requestID) = (state.mode, state.target, state.flowID, state.requestID)
        return .run { send in
            do {
                let target: ReviewWriteRequest
                let detail: ReviewDetail?
                switch mode {
                case .create:
                    guard let initialTarget else { return }
                    target = initialTarget
                    detail = nil
                case .edit(let reviewID):
                    let loadedDetail = try await service.fetchReviewDetail(reviewID: reviewID)
                    guard loadedDetail.reviewID == reviewID else { throw NetworkError.decodingFail }
                    detail = loadedDetail
                    target = .init(placeID: loadedDetail.placeID, placeName: loadedDetail.placeName)
                }
                try Task.checkCancellation()
                let form = service.usesServerForm ? try await service.fetchWritingForm(placeID: target.placeID) : nil
                try Task.checkCancellation()
                let resolvedTarget = ReviewWriteRequest(placeID: target.placeID, placeName: form?.placeName ?? target.placeName)
                await send(.formLoaded(.success(.init(target: resolvedTarget, form: form, detail: detail)), flowID: flowID, requestID: requestID))
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                let message = if let error = error as? NetworkError {
                    Self.loadMessage(for: error)
                } else {
                    "후기 폼을 불러오지 못했어요. 다시 시도해주세요."
                }
                await send(.formLoaded(.failure(message), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.loading)
    }

    func submitEffect(
        mode: State.Mode,
        placeID: Int,
        submission: PlaceReviewSubmission,
        flowID: UUID,
        requestID: Int
    ) -> Effect<Action> {
        let service = service
        return .run { send in
            do {
                switch mode {
                case .create:
                    try await service.createReview(placeID: placeID, submission: submission)
                case .edit(let reviewID):
                    try await service.updateReview(reviewID: reviewID, submission: submission)
                }
                await send(.submissionCompleted(.success(()), flowID: flowID, requestID: requestID))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.submissionCompleted(.failure(Self.submissionMessage(for: error, mode: mode)), flowID: flowID, requestID: requestID))
            } catch {
                await send(.submissionCompleted(.failure(Self.genericSubmissionMessage(for: mode)), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.submission)
    }

    static func loadMessage(for error: NetworkError) -> String {
        if case .networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        if case .apiError(let code, _, _) = error, code == "REVIEW_400_2" {
            return "주차장은 후기를 작성할 수 없어요."
        }
        return "후기 폼을 불러오지 못했어요. 다시 시도해주세요."
    }

    static func submissionMessage(for error: NetworkError, mode: State.Mode) -> String {
        if case .networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }

        if case .apiError(_, let message, _) = error,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        return genericSubmissionMessage(for: mode)
    }

    static func genericSubmissionMessage(for mode: State.Mode) -> String {
        switch mode {
        case .create:
            return "후기를 등록하지 못했어요. 다시 시도해주세요."
        case .edit:
            return "후기를 수정하지 못했어요. 다시 시도해주세요."
        }
    }
}
