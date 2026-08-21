import Foundation

@MainActor
struct MyReviewPostsReducer: Reducer {
    struct State {
        var items: [MyReviewItem] = []
        var isInitialLoading = false
        var hasCompletedInitialLoad = false
        var isNextPageLoading = false
        var errorMessage: String?
        var nextCursor: String?
        var hasNextPage = false
        var requestID = 0
        var hasPracticeRecords = false
        var practiceAvailabilityRequestID = 0
        var deleteTargetReviewID: Int?
        var isDeleting = false
        var deleteErrorMessage: String?
    }

    enum Action {
        case appeared
        case retryRequested
        case reloadRequested
        case lastItemAppeared(MyReviewItem)
        case firstPageLoaded(PageLoadResult, requestID: Int)
        case nextPageLoaded(PageLoadResult, requestID: Int)
        case practiceAvailabilityLoaded(Bool, requestID: Int)
        case deleteRequested(Int)
        case deleteCancelled
        case deleteConfirmed
        case deleteCompleted(DeleteResult, reviewID: Int)
        case editRequested(Int)
        case delegate(Delegate)
    }

    enum Delegate {
        case editingRequested(Int)
        case practiceRecordsRefreshRequested
        case snackbarRequested(String)
    }

    enum PageLoadResult {
        case success(MyReviewPage)
        case failure(String)
    }

    enum DeleteResult {
        case success
        case failure(String)
    }

    private enum EffectID {
        case firstPage
        case nextPage
        case delete
    }

    private let reviewRepository: ReviewRepository
    private let practiceRepository: PracticeRepository

    init(reviewRepository: ReviewRepository, practiceRepository: PracticeRepository) {
        self.reviewRepository = reviewRepository
        self.practiceRepository = practiceRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.isInitialLoading, !state.hasCompletedInitialLoad else { return .none }
            return loadInitialContent(state: &state)

        case .retryRequested, .reloadRequested:
            return loadFirstPage(state: &state)

        case let .lastItemAppeared(item):
            return loadNextPage(after: item, state: &state)

        case let .firstPageLoaded(result, requestID):
            guard requestID == state.requestID else { return .none }
            state.isInitialLoading = false
            state.hasCompletedInitialLoad = true
            apply(result, to: &state)

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

        case let .practiceAvailabilityLoaded(hasPracticeRecords, requestID):
            guard requestID == state.practiceAvailabilityRequestID else { return .none }
            state.hasPracticeRecords = hasPracticeRecords

        case let .deleteRequested(reviewID):
            guard !state.isDeleting, state.items.contains(where: { $0.id == reviewID }) else { return .none }
            state.deleteTargetReviewID = reviewID
            state.deleteErrorMessage = nil

        case .deleteCancelled:
            guard !state.isDeleting else { return .none }
            state.deleteTargetReviewID = nil
            state.deleteErrorMessage = nil

        case .deleteConfirmed:
            guard let reviewID = state.deleteTargetReviewID, !state.isDeleting else { return .none }
            state.isDeleting = true
            state.deleteErrorMessage = nil
            return deleteEffect(reviewID: reviewID)

        case let .deleteCompleted(result, reviewID):
            guard state.deleteTargetReviewID == reviewID, state.isDeleting else { return .none }
            state.isDeleting = false
            switch result {
            case .success:
                state.deleteTargetReviewID = nil
                state.deleteErrorMessage = nil
                return .send(.delegate(.practiceRecordsRefreshRequested))
            case .failure(let message):
                state.deleteErrorMessage = message
            }

        case let .editRequested(reviewID):
            guard state.items.contains(where: { $0.id == reviewID }) else { return .none }
            return .send(.delegate(.editingRequested(reviewID)))

        case .delegate:
            return .none
        }
        return .none
    }
}

private extension MyReviewPostsReducer {
    func apply(_ result: PageLoadResult, to state: inout State) {
        switch result {
        case .success(let page):
            state.items = page.items
            state.hasNextPage = page.hasNext
            state.nextCursor = page.nextCursor
            state.errorMessage = nil
        case .failure(let message):
            state.errorMessage = message
        }
    }

    func prepareFirstPage(state: inout State) -> Int {
        state.items = []
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasNextPage = false
        state.requestID += 1
        return state.requestID
    }

    func loadInitialContent(state: inout State) -> Effect<Action> {
        let requestID = prepareFirstPage(state: &state)
        state.practiceAvailabilityRequestID += 1
        let availabilityRequestID = state.practiceAvailabilityRequestID
        let reviewRepository = reviewRepository
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10))
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
            await send(.practiceAvailabilityLoaded(
                await Self.hasVisitedPractice(using: practiceRepository),
                requestID: availabilityRequestID
            ))
        }
        .cancelTask(id: EffectID.firstPage)
    }

    func loadFirstPage(state: inout State) -> Effect<Action> {
        let requestID = prepareFirstPage(state: &state)
        let reviewRepository = reviewRepository
        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10))
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.firstPage)
    }

    func loadNextPage(after item: MyReviewItem, state: inout State) -> Effect<Action> {
        guard item.id == state.items.last?.id,
              state.hasNextPage,
              let cursor = state.nextCursor,
              !state.isInitialLoading,
              !state.isNextPageLoading
        else { return .none }
        state.isNextPageLoading = true
        state.errorMessage = nil
        let requestID = state.requestID
        let reviewRepository = reviewRepository
        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10, cursor: cursor))
                await send(.nextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.nextPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.nextPage)
    }

    func deleteEffect(reviewID: Int) -> Effect<Action> {
        let reviewRepository = reviewRepository
        return .run { send in
            do {
                try await reviewRepository.delete(reviewID: reviewID)
                await send(.deleteCompleted(.success, reviewID: reviewID))
            } catch {
                await send(.deleteCompleted(.failure(Self.deleteMessage(for: error)), reviewID: reviewID))
            }
        }
        .cancelTask(id: EffectID.delete)
    }

    static func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        return "내 후기를 불러오지 못했어요."
    }

    static func deleteMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "네트워크 연결을 확인해주세요."
        }
        return "후기를 삭제하지 못했어요. 다시 시도해주세요."
    }

    static func hasVisitedPractice(using repository: PracticeRepository) async -> Bool {
        var cursor: String?
        while true {
            guard let page = try? await repository.fetchMyPractices(query: .init(size: 20, cursor: cursor)) else {
                return false
            }
            if page.items.contains(where: { $0.status == .visited }) { return true }
            guard page.hasNext, let nextCursor = page.nextCursor, !nextCursor.isEmpty else { return false }
            cursor = nextCursor
        }
    }
}
