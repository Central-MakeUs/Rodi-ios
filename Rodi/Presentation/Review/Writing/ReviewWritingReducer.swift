import Foundation

struct ReviewWritingReducer: Reducer {
    struct State {
        enum Page: Equatable {
            case hidden
            case loading
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
        var draft = ReviewDraft()
        var isSubmitting = false
        var isDiscardConfirmationPresented = false
        var isCompletionPresented = false
        var isCompletionDismissing = false
        var flowID = UUID()
        var requestID = 0

        var canProceedToSecondPage: Bool {
            draft.canProceedToSecondPage()
        }

        var canSubmit: Bool {
            draft.practiceMethod != nil && !isSubmitting
        }
    }

    enum Action {
        case start(ReviewWriteRequest)
        case editStarted(reviewID: Int)
        case detailLoaded(ReviewRequestResult<ReviewDetail>, flowID: UUID, requestID: Int)
        case recommendationSelected(Bool)
        case difficultySelected(ReviewDifficulty)
        case congestionSelected(ReviewCongestion)
        case cautionChanged(String)
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
        case cancelDetailLoading
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
        case detail
        case submission
        case completionDismissal
    }

    private let service: any ReviewWritingServicing

    init(service: any ReviewWritingServicing) {
        self.service = service
    }
}

// MARK: - Reduce
extension ReviewWritingReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let request):
            state = .init(page: .first, mode: .create, target: request, requestID: state.requestID + 1)
            RodiAnalytics.track(.reviewWritingOpened(mode: "create"))

        case .editStarted(let reviewID):
            state = .init(page: .loading, mode: .edit(reviewID: reviewID), requestID: state.requestID + 1)
            RodiAnalytics.track(.reviewWritingOpened(mode: "edit"))
            return detailEffect(reviewID: reviewID, flowID: state.flowID, requestID: state.requestID)

        case .detailLoaded(let result, let flowID, let requestID):
            guard state.page == .loading,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }

            switch result {
            case .success(let detail):
                guard case .edit(let reviewID) = state.mode, reviewID == detail.reviewID else {
                    return .none
                }
                state.target = .init(placeID: detail.placeID, placeName: detail.placeName)
                state.draft = .init(detail: detail)
                state.page = .first
            case .failure(let message):
                return .send(.delegate(.editingFailed(message)))
            }

        case .recommendationSelected(let value):
            guard state.page == .first else { return .none }
            state.draft.isRecommended = value

        case .difficultySelected(let value):
            guard state.page == .first else { return .none }
            state.draft.difficulty = value

        case .congestionSelected(let value):
            guard state.page == .first else { return .none }
            state.draft.congestion = value

        case .cautionChanged(let value):
            guard state.page == .first else { return .none }
            state.draft.caution = value

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
            guard state.page == .second, value.count <= 150 else { return .none }
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
            return .send(.delegate(.finished))

        case .discardCancelled:
            state.isDiscardConfirmationPresented = false

        case .submitTapped:
            guard state.page == .second,
                  state.canSubmit,
                  let target = state.target,
                  let submission = state.draft.submission()
            else {
                return .none
            }
            state.isSubmitting = true
            state.requestID += 1
            RodiAnalytics.track(
                .reviewSubmitted(
                    mode: state.mode.analyticsName,
                    hasContent: !state.draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            )
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
                RodiAnalytics.track(.reviewCompleted(mode: state.mode.analyticsName))
            case .failure(let message):
                RodiAnalytics.track(.reviewSubmissionFailed(mode: state.mode.analyticsName))
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
                await send(.cancelDetailLoading)
                await send(.cancelSubmission)
            }

        case .cancelDetailLoading:
            return .cancel(id: EffectID.detail)

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

    func detailEffect(reviewID: Int, flowID: UUID, requestID: Int) -> Effect<Action> {
        let service = service
        return .run { send in
            do {
                let detail = try await service.fetchReviewDetail(reviewID: reviewID)
                await send(.detailLoaded(.success(detail), flowID: flowID, requestID: requestID))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.detailLoaded(.failure(Self.detailMessage(for: error)), flowID: flowID, requestID: requestID))
            } catch {
                await send(.detailLoaded(.failure("후기 상세를 불러오지 못했어요. 다시 시도해주세요."), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.detail)
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

    static func detailMessage(for error: NetworkError) -> String {
        if case .networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        return "후기 상세를 불러오지 못했어요. 다시 시도해주세요."
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
