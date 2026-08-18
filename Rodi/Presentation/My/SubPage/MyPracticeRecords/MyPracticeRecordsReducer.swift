import Foundation

@MainActor
struct MyPracticeRecordsReducer: Reducer {
    struct State {
        var items: [MyPracticeItem] = []
        var isInitialLoading = false
        var isNextPageLoading = false
        var errorMessage: String?
        fileprivate var nextCursor: String?
        fileprivate var hasNextPage = false
        fileprivate var requestID = 0
    }

    enum Action {
        case appeared
        case reloadRequested
        case retryTapped
        case lastItemAppeared(MyPracticeItem)
        case firstPageLoaded(PageLoadResult, requestID: Int)
        case nextPageLoaded(PageLoadResult, requestID: Int)
    }

    enum PageLoadResult {
        case success(MyPracticePage)
        case failure(String)
    }

    private enum EffectID {
        case firstPage
        case nextPage
    }

    private let practiceRepository: PracticeRepository

    init(practiceRepository: PracticeRepository) {
        self.practiceRepository = practiceRepository
    }
}

// MARK: - Reduce
extension MyPracticeRecordsReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.isInitialLoading, state.items.isEmpty else { return .none }
            return loadFirstPage(state: &state)

        case .reloadRequested:
            guard !state.isInitialLoading else { return .none }
            return loadFirstPage(state: &state)

        case .retryTapped:
            if state.items.isEmpty {
                guard !state.isInitialLoading else { return .none }
                return loadFirstPage(state: &state)
            }

            guard let lastItem = state.items.last else { return .none }
            return loadNextPage(after: lastItem, state: &state)

        case .lastItemAppeared(let item):
            return loadNextPage(after: item, state: &state)

        case let .firstPageLoaded(result, requestID):
            guard requestID == state.requestID else { return .none }
            state.isInitialLoading = false

            switch result {
            case .success(let page):
                state.items = page.items.filter { $0.status == .visited }
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
                let existingIDs = Set(state.items.map(\.id))
                state.items.append(
                    contentsOf: page.items.filter {
                        $0.status == .visited && !existingIDs.contains($0.id)
                    }
                )
                state.hasNextPage = page.hasNext
                state.nextCursor = page.nextCursor
                state.errorMessage = nil
            case .failure(let message):
                state.errorMessage = message
            }
        }

        return .none
    }
}

// MARK: - Effect
private extension MyPracticeRecordsReducer {

    func loadFirstPage(state: inout State) -> Effect<Action> {
        state.items = []
        state.nextCursor = nil
        state.hasNextPage = false
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.requestID += 1
        let requestID = state.requestID
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let page = try await practiceRepository.fetchMyPractices(query: .init(size: 20))
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.firstPage)
    }

    func loadNextPage(after item: MyPracticeItem, state: inout State) -> Effect<Action> {
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
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let page = try await practiceRepository.fetchMyPractices(query: .init(size: 20, cursor: cursor))
                await send(.nextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.nextPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.nextPage)
    }

    static func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "연습기록을 불러오지 못했어요."
    }
}
