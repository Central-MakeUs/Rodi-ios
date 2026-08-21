import Foundation

@MainActor
struct MyCoursePostsReducer: Reducer {
    struct State {
        var items: [MyCourseItem] = []
        var selectedFilter: MyPostsCourseFilter = .all
        var isInitialLoading = false
        var hasCompletedInitialLoad = false
        var isNextPageLoading = false
        var errorMessage: String?
        var nextCursor: String?
        var hasNextPage = false
        var requestID = 0
        var deleteTargetCourseID: Int64?
        var isDeleting = false
        var deleteErrorMessage: String?
    }

    enum Action {
        case appeared
        case retryRequested
        case filterSelected(MyPostsCourseFilter)
        case lastItemAppeared(MyCourseItem)
        case firstPageLoaded(PageLoadResult, requestID: Int)
        case nextPageLoaded(PageLoadResult, requestID: Int)
        case deleteRequested(Int64)
        case deleteCancelled
        case deleteConfirmed
        case deleteCompleted(DeleteResult, courseID: Int64)
        case delegate(Delegate)
    }

    enum Delegate { case snackbarRequested(String) }
    enum PageLoadResult { case success(MyCoursePage); case failure(String) }
    enum DeleteResult { case success; case failure(String) }
    private enum EffectID { case firstPage, nextPage, delete }
    private let courseRepository: CourseRepository

    init(courseRepository: CourseRepository) { self.courseRepository = courseRepository }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.isInitialLoading, !state.hasCompletedInitialLoad else { return .none }
            return loadFirstPage(state: &state)
        case .retryRequested:
            return loadFirstPage(state: &state)
        case let .filterSelected(filter):
            guard state.selectedFilter != filter else { return .none }
            state.selectedFilter = filter
            RodiAnalytics.track(.myCourseFilterChanged(status: filter.analyticsName))
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
            case .failure(let message): state.errorMessage = message
            }
        case let .deleteRequested(courseID):
            guard !state.isDeleting, state.items.contains(where: { $0.id == courseID }) else { return .none }
            state.deleteTargetCourseID = courseID
            state.deleteErrorMessage = nil
        case .deleteCancelled:
            guard !state.isDeleting else { return .none }
            state.deleteTargetCourseID = nil
            state.deleteErrorMessage = nil
        case .deleteConfirmed:
            guard let courseID = state.deleteTargetCourseID, !state.isDeleting else { return .none }
            state.isDeleting = true
            state.deleteErrorMessage = nil
            return deleteEffect(courseID: courseID)
        case let .deleteCompleted(result, courseID):
            guard state.deleteTargetCourseID == courseID, state.isDeleting else { return .none }
            state.isDeleting = false
            switch result {
            case .success:
                state.deleteTargetCourseID = nil
                state.deleteErrorMessage = nil
                RodiAnalytics.track(.myCourseDeleted)
                return .send(.delegate(.snackbarRequested("코스를 삭제했습니다.")))
            case .failure(let message): state.deleteErrorMessage = message
            }
        case .delegate: return .none
        }
        return .none
    }
}

private extension MyCoursePostsReducer {
    func apply(_ result: PageLoadResult, to state: inout State) {
        switch result {
        case .success(let page):
            state.items = page.items
            state.hasNextPage = page.hasNext
            state.nextCursor = page.nextCursor
            state.errorMessage = nil
        case .failure(let message): state.errorMessage = message
        }
    }

    func loadFirstPage(state: inout State) -> Effect<Action> {
        state.items = []
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasNextPage = false
        state.requestID += 1
        let requestID = state.requestID
        let filter = state.selectedFilter
        let courseRepository = courseRepository
        return .run { send in
            do {
                let page = try await courseRepository.fetchMyCourses(query: .init(status: filter.approvalStatus, size: 20))
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }.cancelTask(id: EffectID.firstPage)
    }

    func loadNextPage(after item: MyCourseItem, state: inout State) -> Effect<Action> {
        guard item.id == state.items.last?.id, state.hasNextPage, let cursor = state.nextCursor,
              !state.isInitialLoading, !state.isNextPageLoading else { return .none }
        state.isNextPageLoading = true
        state.errorMessage = nil
        let requestID = state.requestID
        let filter = state.selectedFilter
        let courseRepository = courseRepository
        return .run { send in
            do {
                let page = try await courseRepository.fetchMyCourses(query: .init(status: filter.approvalStatus, size: 20, cursor: cursor))
                await send(.nextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.nextPageLoaded(.failure(Self.message(for: error)), requestID: requestID))
            }
        }.cancelTask(id: EffectID.nextPage)
    }

    func deleteEffect(courseID: Int64) -> Effect<Action> {
        let courseRepository = courseRepository
        return .run { send in
            do {
                try await courseRepository.deleteMyCourse(courseID: courseID)
                await send(.deleteCompleted(.success, courseID: courseID))
            } catch {
                await send(.deleteCompleted(.failure(Self.deleteMessage(for: error)), courseID: courseID))
            }
        }.cancelTask(id: EffectID.delete)
    }

    static func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error { return "네트워크 연결을 확인해주세요." }
        return "등록한 코스를 불러오지 못했어요."
    }
    static func deleteMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error { return "네트워크 연결을 확인해주세요." }
        return "코스를 삭제하지 못했어요. 다시 시도해주세요."
    }
}

private extension MyPostsCourseFilter {
    var analyticsName: String {
        switch self {
        case .all: "all"
        case .approved: "approved"
        case .pending: "pending"
        case .rejected: "rejected"
        }
    }
}
