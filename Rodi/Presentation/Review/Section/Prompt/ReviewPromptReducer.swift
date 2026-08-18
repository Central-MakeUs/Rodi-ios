import Foundation

struct ReviewPromptReducer: Reducer {
    struct State {
        enum Presentation: Equatable {
            case hidden
            case preparing
            case prompt
        }

        var presentation: Presentation = .hidden
        var target: ReviewTarget?
        var allowsSkipReason = true
        var allowsReviewWriting = true
        var visitedSnackbarMessage: String?
        var isVisitSubmitting = false
        var flowID = UUID()
        var requestID = 0
    }

    enum Action {
        case start(
            placeID: Int,
            placeName: String,
            allowsSkipReason: Bool,
            allowsReviewWriting: Bool,
            visitedSnackbarMessage: String?
        )
        case targetPrepared(ReviewRequestResult<ReviewTarget>, flowID: UUID, requestID: Int)
        case visitedTapped
        case notVisitedTapped
        case closeTapped
        case visitSubmissionChanged(Bool)
        case reset
        case delegate(Delegate)
    }

    enum Delegate {
        case writingRequested(ReviewWriteRequest)
        case skipReasonRequested(ReviewTarget)
        case dismissed
        case preparationFailed(String)
        case showSnackbar(String)
        case visitedWithoutReview(String)
    }

    private enum EffectID {
        case preparation
    }

    private let service: any ReviewPromptServicing

    init(service: any ReviewPromptServicing) {
        self.service = service
    }
}

// MARK: - Reduce
extension ReviewPromptReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .start(placeID, placeName, allowsSkipReason, allowsReviewWriting, visitedSnackbarMessage):
            state = .init(
                presentation: .prompt,
                target: .init(placeID: placeID, practiceID: nil, placeName: placeName),
                allowsSkipReason: allowsSkipReason,
                allowsReviewWriting: allowsReviewWriting,
                visitedSnackbarMessage: visitedSnackbarMessage
            )

        case .targetPrepared(let result, let flowID, let requestID):
            guard state.presentation == .preparing,
                  state.flowID == flowID,
                  state.requestID == requestID
            else {
                return .none
            }

            switch result {
            case .success(let preparedTarget):
                state.target = preparedTarget
                return .send(.delegate(.skipReasonRequested(preparedTarget)))

            case .failure(let message):
                state = .init()
                return .send(.delegate(.preparationFailed(message)))
            }

        case .visitedTapped:
            guard state.presentation == .prompt,
                  let target = state.target
            else {
                return .none
            }
            guard state.allowsReviewWriting else {
                return state.visitedSnackbarMessage
                    .map { .send(.delegate(.visitedWithoutReview($0))) }
                    ?? .send(.delegate(.dismissed))
            }
            return .send(.delegate(.writingRequested(.init(
                placeID: target.placeID,
                placeName: target.placeName
            ))))

        case .notVisitedTapped:
            guard state.presentation == .prompt,
                  let target = state.target
            else {
                return .none
            }
            guard state.allowsSkipReason else {
                return .send(.delegate(.dismissed))
            }
            state.presentation = .preparing
            state.requestID += 1
            return prepareTargetEffect(
                placeID: target.placeID,
                flowID: state.flowID,
                requestID: state.requestID
            )

        case .closeTapped:
            guard state.presentation == .prompt else { return .none }
            return .send(.delegate(.dismissed))

        case .visitSubmissionChanged(let isSubmitting):
            guard state.presentation == .prompt else { return .none }
            state.isVisitSubmitting = isSubmitting

        case .reset:
            state = .init()
            return .cancel(id: EffectID.preparation)

        case .delegate:
            return .none
        }

        return .none
    }
}

// MARK: - Effect
private extension ReviewPromptReducer {

    func prepareTargetEffect(placeID: Int, flowID: UUID, requestID: Int) -> Effect<Action> {
        let service = service
        return .run { send in
            do {
                let target = try await service.prepareTarget(placeID: placeID)
                await send(.targetPrepared(.success(target), flowID: flowID, requestID: requestID))
            } catch is CancellationError {
                return
            } catch let error as ReviewTargetPreparationError {
                RodiLogger.error(
                    "Review target preparation failed: endpoint=\(error.endpoint), error=\(error.underlyingError.localizedDescription)"
                )
                await send(.targetPrepared(.failure("후기 등록 대상을 준비하지 못했어요."), flowID: flowID, requestID: requestID))
            } catch {
                RodiLogger.error("Review target preparation failed: error=\(error.localizedDescription)")
                await send(.targetPrepared(.failure("후기 등록 대상을 준비하지 못했어요."), flowID: flowID, requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.preparation)
    }

}
