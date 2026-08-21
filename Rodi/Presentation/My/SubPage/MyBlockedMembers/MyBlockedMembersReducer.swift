//
//  MyBlockedMembersReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct MyBlockedMembersReducer: Reducer {
    struct State {
        var items: [BlockedMember] = []
        var isInitialLoading = false
        var hasCompletedInitialLoad = false
        var isNextPageLoading = false
        var errorMessage: String?
        var nextCursor: String?
        var hasNextPage = false
        var requestID = 0
        var unblockingMemberIDs: Set<Int> = []
        var snackbarMessage: String?
    }

    enum Action {
        case appeared
        case retryInitialTapped
        case retryNextPageTapped
        case lastItemAppeared(BlockedMember)
        case firstPageLoaded(PageLoadResult, requestID: Int)
        case nextPageLoaded(PageLoadResult, requestID: Int)
        case unblockTapped(memberID: Int)
        case unblockCompleted(UnblockResult, memberID: Int)
        case snackbarDismissed(String)
    }

    enum PageLoadResult {
        case success(BlockedMemberPage)
        case failure(String)
    }

    enum UnblockResult {
        case success
        case failure(String)
    }

    private enum EffectID: Hashable {
        case firstPage
        case nextPage
        case unblock(Int)
        case snackbar
    }

    private let memberRepository: MemberRepository

    init(memberRepository: MemberRepository) {
        self.memberRepository = memberRepository
    }
}

// MARK: - Reduce
extension MyBlockedMembersReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.isInitialLoading, !state.hasCompletedInitialLoad else { return .none }
            return loadFirstPage(state: &state)

        case .retryInitialTapped:
            guard !state.isInitialLoading else { return .none }
            return loadFirstPage(state: &state)

        case .retryNextPageTapped:
            guard let lastItem = state.items.last else { return .none }
            return loadNextPage(after: lastItem, state: &state)

        case .lastItemAppeared(let item):
            return loadNextPage(after: item, state: &state)

        case let .firstPageLoaded(result, requestID):
            guard requestID == state.requestID else { return .none }
            state.isInitialLoading = false
            state.hasCompletedInitialLoad = true

            switch result {
            case .success(let page):
                state.items = page.items
                state.hasNextPage = page.hasNext
                state.nextCursor = page.nextCursor
                state.errorMessage = nil
            case .failure(let message):
                state.errorMessage = message
            }

        case let .nextPageLoaded(result, requestID):
            guard requestID == state.requestID else { return .none }
            state.isNextPageLoading = false

            switch result {
            case .success(let page):
                var existingIDs = Set(state.items.map(\.id))
                state.items.append(contentsOf: page.items.filter { existingIDs.insert($0.id).inserted })
                state.hasNextPage = page.hasNext
                state.nextCursor = page.nextCursor
                state.errorMessage = nil
            case .failure(let message):
                state.errorMessage = message
            }

        case .unblockTapped(let memberID):
            guard state.items.contains(where: { $0.id == memberID }),
                  !state.unblockingMemberIDs.contains(memberID)
            else {
                return .none
            }
            state.unblockingMemberIDs.insert(memberID)
            return unblock(memberID: memberID)

        case let .unblockCompleted(result, memberID):
            guard state.unblockingMemberIDs.remove(memberID) != nil else { return .none }

            switch result {
            case .success:
                state.items.removeAll { $0.id == memberID }
            case .failure(let message):
                state.snackbarMessage = message
                return dismissSnackbar(message)
            }

        case .snackbarDismissed(let message):
            guard state.snackbarMessage == message else { return .none }
            state.snackbarMessage = nil
        }

        return .none
    }
}

// MARK: - Effects
private extension MyBlockedMembersReducer {

    func loadFirstPage(state: inout State) -> Effect<Action> {
        state.items = []
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasNextPage = false
        state.requestID += 1
        let requestID = state.requestID
        let memberRepository = memberRepository

        return .run { send in
            do {
                RodiLogger.debug("차단목록 조회 시작: GET /api/v1/members/me/blocks")
                let page = try await memberRepository.fetchBlockedMembers(query: .init(size: 20))
                RodiLogger.debug("차단목록 조회 성공: GET /api/v1/members/me/blocks items=\(page.items.count)")
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                RodiLogger.warning(
                    "차단목록 조회 실패: endpoint=GET /api/v1/members/me/blocks, \(Self.diagnosticDescription(for: error))"
                )
                await send(.firstPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.firstPage)
    }

    func loadNextPage(after item: BlockedMember, state: inout State) -> Effect<Action> {
        guard item.id == state.items.last?.id,
              state.hasNextPage,
              let cursor = state.nextCursor,
              !state.isInitialLoading,
              !state.isNextPageLoading
        else {
            return .none
        }

        state.isNextPageLoading = true
        state.errorMessage = nil
        let requestID = state.requestID
        let memberRepository = memberRepository

        return .run { send in
            do {
                let page = try await memberRepository.fetchBlockedMembers(query: .init(size: 20, cursor: cursor))
                await send(.nextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.nextPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.nextPage)
    }

    func unblock(memberID: Int) -> Effect<Action> {
        let memberRepository = memberRepository

        return .run { send in
            do {
                try await memberRepository.unblock(memberID: memberID)
                await send(.unblockCompleted(.success, memberID: memberID))
            } catch {
                await send(.unblockCompleted(.failure(Self.unblockMessage(for: error)), memberID: memberID))
            }
        }
        .cancelTask(id: EffectID.unblock(memberID))
    }

    func dismissSnackbar(_ message: String) -> Effect<Action> {
        .run { send in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    static func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        return "차단목록을 불러오지 못했어요."
    }

    static func diagnosticDescription(for error: Error) -> String {
        guard let networkError = error as? NetworkError else {
            return "kind=unexpected, type=\(String(reflecting: type(of: error)))"
        }

        switch networkError {
        case .apiError(let code, let message, let httpStatusCode):
            return "kind=apiError, code=\(code), httpStatus=\(httpStatusCode.map(String.init) ?? "nil"), message=\(message)"
        case .httpStatusCode(let statusCode):
            return "kind=httpStatusCode, httpStatus=\(statusCode)"
        case .decodingFail:
            return "kind=decodingFail, response=blocked-member cursor page or blockedAt date"
        default:
            return "kind=\(networkError.localizedDescription)"
        }
    }

    static func unblockMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        return "차단을 해제하지 못했어요. 다시 시도해주세요."
    }
}
