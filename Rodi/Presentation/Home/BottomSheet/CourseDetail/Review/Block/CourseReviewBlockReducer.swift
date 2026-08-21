import Foundation

struct CourseReviewBlockReducer: Reducer {
    enum BlockResult { case success, failure(String) }
    struct State: Equatable {
        var memberID: Int?
        var isConfirmationPresented = false
        var isBlocking = false
        var revision = UUID()
    }

    enum Action {
        case request(memberID: Int)
        case cancelTapped
        case confirmTapped
        case completed(BlockResult, memberID: Int, revision: UUID)
        case reset
        case delegate(Delegate)
    }
    enum Delegate { case blocked(memberID: Int), requestAuthentication, showSnackbar(String) }
    private enum EffectID: Hashable { case block }

    private let repository: MemberRepository
    private let hasActiveSession: () -> Bool

    init(repository: MemberRepository, hasActiveSession: @escaping () -> Bool) {
        self.repository = repository
        self.hasActiveSession = hasActiveSession
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .request(let memberID):
            guard !state.isConfirmationPresented, !state.isBlocking else { return .none }
            state.memberID = memberID; state.isConfirmationPresented = true
        case .cancelTapped:
            guard state.isConfirmationPresented, !state.isBlocking else { return .none }
            state = .init()
        case .confirmTapped:
            guard let memberID = state.memberID, state.isConfirmationPresented, !state.isBlocking else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            state.isBlocking = true; state.revision = UUID()
            return block(memberID: memberID, revision: state.revision)
        case let .completed(result, memberID, revision):
            guard state.memberID == memberID, state.revision == revision, state.isBlocking else { return .none }
            state.isBlocking = false
            switch result { case .success: return .send(.delegate(.blocked(memberID: memberID))); case .failure(let message): return .send(.delegate(.showSnackbar(message))) }
        case .reset: state = .init(); return .cancel(id: EffectID.block)
        case .delegate: return .none
        }
        return .none
    }
}

private extension CourseReviewBlockReducer {
    func block(memberID: Int, revision: UUID) -> Effect<Action> {
        let repository = repository
        return .run { send in
            do { try await repository.block(memberID: memberID); await send(.completed(.success, memberID: memberID, revision: revision)) }
            catch is CancellationError { }
            catch let error as NetworkError {
                if requiresAuthentication(error) { await send(.delegate(.requestAuthentication)) }
                await send(.completed(.failure("사용자를 차단하지 못했어요. 다시 시도해주세요."), memberID: memberID, revision: revision))
            } catch { await send(.completed(.failure("사용자를 차단하지 못했어요. 다시 시도해주세요."), memberID: memberID, revision: revision)) }
        }.cancelTask(id: EffectID.block)
    }
    func requiresAuthentication(_ error: NetworkError) -> Bool {
        switch error { case .refreshFailGoRoot, .httpStatusCode(401): true; case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"; default: false }
    }
}
