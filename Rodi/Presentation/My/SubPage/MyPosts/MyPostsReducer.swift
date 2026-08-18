//
//  MyPostsReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct MyPostsReducer: Reducer {
    enum Tab: Equatable {
        case courses
        case reviews
    }

    enum CourseFilter: CaseIterable, Equatable, Identifiable {
        case all
        case approved
        case pending
        case rejected

        var id: Self { self }

        var title: String {
            switch self {
            case .all: "전체"
            case .approved: "승인"
            case .pending: "검토중"
            case .rejected: "반려"
            }
        }

        var approvalStatus: MyCourseApprovalStatus? {
            switch self {
            case .all: nil
            case .approved: .approved
            case .pending: .pending
            case .rejected: .rejected
            }
        }
    }

    struct State {
        var selectedTab: Tab = .courses

        var items: [MyReviewItem] = []
        var isInitialLoading = false
        var hasCompletedInitialLoad = false
        var isNextPageLoading = false
        var errorMessage: String?
        var nextCursor: String?
        var hasNextPage = false
        var requestID = 0

        var courseItems: [MyCourseItem] = []
        var selectedCourseFilter: CourseFilter = .all
        var isCourseInitialLoading = false
        var hasCompletedCourseInitialLoad = false
        var isCourseNextPageLoading = false
        var courseErrorMessage: String?
        var courseNextCursor: String?
        var hasNextCoursePage = false
        var courseRequestID = 0

        var deleteTargetReviewID: Int?
        var isDeleting = false
        var deleteErrorMessage: String?
        var deleteTargetCourseID: Int64?
        var isDeletingCourse = false
        var courseDeleteErrorMessage: String?
        var snackbarMessage: String?

        var practiceRecordsRefreshRequestID = 0
        var pendingEditReviewID: Int?
        var hasPracticeRecords = false
        var practiceAvailabilityRequestID = 0
    }

    enum Action {
        case appeared
        case tabSelected(Tab)
        case retryTapped
        case reloadReviewsRequested

        case lastItemAppeared(MyReviewItem)
        case firstPageLoaded(PageLoadResult, requestID: Int)
        case nextPageLoaded(PageLoadResult, requestID: Int)
        case practiceAvailabilityLoaded(Bool, requestID: Int)

        case courseFilterSelected(CourseFilter)
        case courseLastItemAppeared(MyCourseItem)
        case courseFirstPageLoaded(CoursePageLoadResult, requestID: Int)
        case courseNextPageLoaded(CoursePageLoadResult, requestID: Int)

        case deleteRequested(reviewID: Int)
        case deleteCancelled
        case deleteConfirmed
        case deleteCompleted(DeleteResult, reviewID: Int)
        case deleteCourseRequested(courseID: Int64)
        case deleteCourseCancelled
        case deleteCourseConfirmed
        case deleteCourseCompleted(DeleteResult, courseID: Int64)

        case editRequested(reviewID: Int)
        case editRequestHandled(reviewID: Int)
        case snackbarDismissed(String)
    }

    enum PageLoadResult {
        case success(MyReviewPage)
        case failure(String)
    }

    enum CoursePageLoadResult {
        case success(MyCoursePage)
        case failure(String)
    }

    enum DeleteResult {
        case success
        case failure(String)
    }

    private enum EffectID {
        case reviewFirstPage
        case reviewNextPage
        case courseFirstPage
        case courseNextPage
        case reviewDelete
        case courseDelete
        case snackbar
    }

    private let reviewRepository: ReviewRepository
    private let practiceRepository: PracticeRepository
    private let courseRepository: CourseRepository

    init(
        reviewRepository: ReviewRepository,
        practiceRepository: PracticeRepository,
        courseRepository: CourseRepository
    ) {
        self.reviewRepository = reviewRepository
        self.practiceRepository = practiceRepository
        self.courseRepository = courseRepository
    }
}

// MARK: - Reduce
extension MyPostsReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            RodiAnalytics.track(.myActivityOpened(tab: state.selectedTab.analyticsName))
            return loadSelectedTabIfNeeded(state: &state)

        case .tabSelected(let tab):
            guard state.selectedTab != tab else { return .none }
            state.selectedTab = tab
            RodiAnalytics.track(.myActivityOpened(tab: tab.analyticsName))
            return loadSelectedTabIfNeeded(state: &state)

        case .retryTapped:
            return state.selectedTab == .courses
                ? loadCourseFirstPage(state: &state)
                : loadReviewFirstPage(state: &state)

        case .reloadReviewsRequested:
            return loadReviewFirstPage(state: &state)

        case .lastItemAppeared(let item):
            return loadReviewNextPage(after: item, state: &state)

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

        case let .practiceAvailabilityLoaded(hasPracticeRecords, requestID):
            guard requestID == state.practiceAvailabilityRequestID else { return .none }
            state.hasPracticeRecords = hasPracticeRecords

        case .courseFilterSelected(let filter):
            guard state.selectedCourseFilter != filter else { return .none }
            state.selectedCourseFilter = filter
            RodiAnalytics.track(.myCourseFilterChanged(status: filter.analyticsName))
            return loadCourseFirstPage(state: &state)

        case .courseLastItemAppeared(let item):
            return loadCourseNextPage(after: item, state: &state)

        case let .courseFirstPageLoaded(result, requestID):
            guard requestID == state.courseRequestID else { return .none }
            state.isCourseInitialLoading = false
            state.hasCompletedCourseInitialLoad = true

            switch result {
            case .success(let page):
                state.courseItems = page.items
                state.hasNextCoursePage = page.hasNext
                state.courseNextCursor = page.nextCursor
                state.courseErrorMessage = nil
            case .failure(let message):
                state.courseErrorMessage = message
            }

        case let .courseNextPageLoaded(result, requestID):
            guard requestID == state.courseRequestID else { return .none }
            state.isCourseNextPageLoading = false

            switch result {
            case .success(let page):
                var existingIDs = Set(state.courseItems.map(\.id))
                state.courseItems.append(contentsOf: page.items.filter { existingIDs.insert($0.id).inserted })
                state.hasNextCoursePage = page.hasNext
                state.courseNextCursor = page.nextCursor
                state.courseErrorMessage = nil
            case .failure(let message):
                state.courseErrorMessage = message
            }

        case .deleteRequested(let reviewID):
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
            return deleteReviewEffect(reviewID: reviewID)

        case let .deleteCompleted(result, reviewID):
            guard state.deleteTargetReviewID == reviewID, state.isDeleting else { return .none }
            state.isDeleting = false

            switch result {
            case .success:
                state.deleteTargetReviewID = nil
                state.deleteErrorMessage = nil
                state.practiceRecordsRefreshRequestID += 1
                return refreshAfterReviewDelete(state: &state)
            case .failure(let message):
                state.deleteErrorMessage = message
            }

        case .deleteCourseRequested(let courseID):
            guard !state.isDeletingCourse, state.courseItems.contains(where: { $0.id == courseID }) else { return .none }
            state.deleteTargetCourseID = courseID
            state.courseDeleteErrorMessage = nil

        case .deleteCourseCancelled:
            guard !state.isDeletingCourse else { return .none }
            state.deleteTargetCourseID = nil
            state.courseDeleteErrorMessage = nil

        case .deleteCourseConfirmed:
            guard let courseID = state.deleteTargetCourseID, !state.isDeletingCourse else { return .none }
            state.isDeletingCourse = true
            state.courseDeleteErrorMessage = nil
            return deleteCourseEffect(courseID: courseID)

        case let .deleteCourseCompleted(result, courseID):
            guard state.deleteTargetCourseID == courseID, state.isDeletingCourse else { return .none }
            state.isDeletingCourse = false

            switch result {
            case .success:
                state.deleteTargetCourseID = nil
                state.courseDeleteErrorMessage = nil
                RodiAnalytics.track(.myCourseDeleted)
                return refreshAfterCourseDelete(state: &state)
            case .failure(let message):
                state.courseDeleteErrorMessage = message
            }

        case .editRequested(let reviewID):
            guard state.items.contains(where: { $0.id == reviewID }) else { return .none }
            state.pendingEditReviewID = reviewID

        case .editRequestHandled(let reviewID):
            guard state.pendingEditReviewID == reviewID else { return .none }
            state.pendingEditReviewID = nil

        case .snackbarDismissed(let message):
            guard state.snackbarMessage == message else { return .none }
            state.snackbarMessage = nil
        }

        return .none
    }
}

private extension MyPostsReducer.Tab {
    var analyticsName: String {
        switch self {
        case .courses: "courses"
        case .reviews: "reviews"
        }
    }
}

private extension MyPostsReducer.CourseFilter {
    var analyticsName: String {
        switch self {
        case .all: "all"
        case .approved: "approved"
        case .pending: "pending"
        case .rejected: "rejected"
        }
    }
}

// MARK: - Effects
private extension MyPostsReducer {

    func loadSelectedTabIfNeeded(state: inout State) -> Effect<Action> {
        switch state.selectedTab {
        case .courses:
            guard !state.isCourseInitialLoading, !state.hasCompletedCourseInitialLoad else { return .none }
            return loadCourseFirstPage(state: &state)
        case .reviews:
            guard !state.isInitialLoading, !state.hasCompletedInitialLoad else { return .none }
            return loadReviewInitialContent(state: &state)
        }
    }

    func loadReviewInitialContent(state: inout State) -> Effect<Action> {
        state.items = []
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasNextPage = false
        state.requestID += 1
        state.practiceAvailabilityRequestID += 1
        let reviewRequestID = state.requestID
        let practiceAvailabilityRequestID = state.practiceAvailabilityRequestID
        let reviewRepository = reviewRepository
        let practiceRepository = practiceRepository

        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10))
                await send(.firstPageLoaded(.success(page), requestID: reviewRequestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.reviewMessage(for: error)), requestID: reviewRequestID))
            }

            await send(.practiceAvailabilityLoaded(
                await Self.hasVisitedPractice(using: practiceRepository),
                requestID: practiceAvailabilityRequestID
            ))
        }
        .cancelTask(id: EffectID.reviewFirstPage)
    }

    func loadReviewFirstPage(state: inout State) -> Effect<Action> {
        state.items = []
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.errorMessage = nil
        state.nextCursor = nil
        state.hasNextPage = false
        state.requestID += 1
        let requestID = state.requestID
        let reviewRepository = reviewRepository

        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10))
                await send(.firstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.firstPageLoaded(.failure(Self.reviewMessage(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.reviewFirstPage)
    }

    func loadReviewNextPage(after item: MyReviewItem, state: inout State) -> Effect<Action> {
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
        let reviewRepository = reviewRepository

        return .run { send in
            do {
                let page = try await reviewRepository.fetchMyReviews(query: .init(size: 10, cursor: cursor))
                await send(.nextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.nextPageLoaded(.failure(Self.reviewMessage(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.reviewNextPage)
    }

    func loadCourseFirstPage(state: inout State) -> Effect<Action> {
        state.courseItems = []
        state.isCourseInitialLoading = true
        state.isCourseNextPageLoading = false
        state.courseErrorMessage = nil
        state.courseNextCursor = nil
        state.hasNextCoursePage = false
        state.courseRequestID += 1
        let requestID = state.courseRequestID
        let filter = state.selectedCourseFilter
        let courseRepository = courseRepository

        return .run { send in
            do {
                let page = try await courseRepository.fetchMyCourses(
                    query: .init(status: filter.approvalStatus, size: 20)
                )
                await send(.courseFirstPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.courseFirstPageLoaded(.failure(Self.courseMessage(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.courseFirstPage)
    }

    func loadCourseNextPage(after item: MyCourseItem, state: inout State) -> Effect<Action> {
        guard item.id == state.courseItems.last?.id,
              state.hasNextCoursePage,
              let cursor = state.courseNextCursor,
              !state.isCourseInitialLoading,
              !state.isCourseNextPageLoading
        else {
            return .none
        }

        state.isCourseNextPageLoading = true
        state.courseErrorMessage = nil
        let requestID = state.courseRequestID
        let filter = state.selectedCourseFilter
        let courseRepository = courseRepository

        return .run { send in
            do {
                let page = try await courseRepository.fetchMyCourses(
                    query: .init(status: filter.approvalStatus, size: 20, cursor: cursor)
                )
                await send(.courseNextPageLoaded(.success(page), requestID: requestID))
            } catch {
                await send(.courseNextPageLoaded(.failure(Self.courseMessage(for: error)), requestID: requestID))
            }
        }
        .cancelTask(id: EffectID.courseNextPage)
    }

    func deleteReviewEffect(reviewID: Int) -> Effect<Action> {
        let reviewRepository = reviewRepository
        return .run { send in
            do {
                try await reviewRepository.delete(reviewID: reviewID)
                await send(.deleteCompleted(.success, reviewID: reviewID))
            } catch {
                await send(.deleteCompleted(.failure(Self.reviewDeleteMessage(for: error)), reviewID: reviewID))
            }
        }
        .cancelTask(id: EffectID.reviewDelete)
    }

    func deleteCourseEffect(courseID: Int64) -> Effect<Action> {
        let courseRepository = courseRepository
        return .run { send in
            do {
                try await courseRepository.deleteMyCourse(courseID: courseID)
                await send(.deleteCourseCompleted(.success, courseID: courseID))
            } catch {
                await send(.deleteCourseCompleted(.failure(Self.courseDeleteMessage(for: error)), courseID: courseID))
            }
        }
        .cancelTask(id: EffectID.courseDelete)
    }

    func refreshAfterReviewDelete(state: inout State) -> Effect<Action> {
        let message = "후기를 삭제했습니다."
        state.snackbarMessage = message

        return .run { send in
            await send(.reloadReviewsRequested)
            try? await Task.sleep(for: .seconds(3))
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    func refreshAfterCourseDelete(state: inout State) -> Effect<Action> {
        let message = "코스를 삭제했습니다."
        state.snackbarMessage = message

        return .run { send in
            await send(.retryTapped)
            try? await Task.sleep(for: .seconds(3))
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    static func reviewMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "내 후기를 불러오지 못했어요."
    }

    static func courseMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "등록한 코스를 불러오지 못했어요."
    }

    static func reviewDeleteMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "후기를 삭제하지 못했어요. 다시 시도해주세요."
    }

    static func courseDeleteMessage(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "코스를 삭제하지 못했어요. 다시 시도해주세요."
    }

    static func hasVisitedPractice(using repository: PracticeRepository) async -> Bool {
        var cursor: String?

        while true {
            guard let page = try? await repository.fetchMyPractices(query: .init(size: 20, cursor: cursor))
            else {
                return false
            }
            if page.items.contains(where: { $0.status == .visited }) {
                return true
            }
            guard page.hasNext, let nextCursor = page.nextCursor, !nextCursor.isEmpty else {
                return false
            }
            cursor = nextCursor
        }
    }
}
