import Foundation

struct CourseRegistrationTutorialReducer: Reducer {
    struct State: Equatable {
        var page = 0
        var isCompleting = false
        var errorMessage: String?
        var errorRevision = 0
        let sessionID = UUID()
        var activeRequestID: UUID?
    }

    enum Action {
        case pageChanged(Int)
        case closeTapped
        case completionTapped
        case completionFinished(UUID, Result<Void, NetworkError>)
        case errorDismissed(UUID, Int)
        case deactivated
        case delegate(Delegate)
    }

    enum Delegate {
        case completed
        case closeRequested
    }

    private let memberRepository: MemberRepository

    private enum EffectID: Hashable {
        case completion
        case errorDismissal
    }

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .pageChanged(let page):
            state.page = min(max(page, 0), 2)

        case .closeTapped:
            guard !state.isCompleting else { return .none }
            guard state.page == 0 else {
                state.page -= 1
                return .none
            }
            return .send(.delegate(.closeRequested))

        case .completionTapped:
            guard state.page == 2, !state.isCompleting else { return .none }
            state.isCompleting = true
            state.errorMessage = nil
            let requestID = UUID()
            state.activeRequestID = requestID
            return .run { send in
                do {
                    _ = try await memberRepository.completeCourseTutorial()
                    await send(.completionFinished(requestID, .success(())))
                } catch is CancellationError {
                    return
                } catch let error as NetworkError {
                    await send(.completionFinished(requestID, .failure(error)))
                } catch {
                    await send(.completionFinished(requestID, .failure(.unknown(errorCode: "unknown"))))
                }
            }
            .cancelTask(id: EffectID.completion)

        case .completionFinished(let requestID, let result):
            guard state.activeRequestID == requestID else { return .none }
            state.activeRequestID = nil
            state.isCompleting = false
            switch result {
            case .success:
                return .send(.delegate(.completed))
            case .failure:
                state.errorMessage = "튜토리얼 완료를 저장하지 못했어요. 다시 시도해 주세요."
                state.errorRevision += 1
                return scheduleErrorDismissal(state: state)
            }

        case .errorDismissed(let sessionID, let revision):
            guard state.sessionID == sessionID, state.errorRevision == revision else { return .none }
            state.errorMessage = nil

        case .deactivated:
            state.activeRequestID = nil
            state.isCompleting = false
            state.errorMessage = nil
            return .cancel(id: EffectID.completion)

        case .delegate:
            return .none
        }

        return .none
    }

    private func scheduleErrorDismissal(state: State) -> Effect<Action> {
        let sessionID = state.sessionID
        let revision = state.errorRevision
        return .run { send in
            do {
                try await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await send(.errorDismissed(sessionID, revision))
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
        .cancelTask(id: EffectID.errorDismissal)
    }
}
