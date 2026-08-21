import Foundation

@MainActor
struct MyPostsReducer: Reducer {
    typealias Tab = MyPostsTab
    typealias CourseFilter = MyPostsCourseFilter
    typealias State = MyPostsState

    enum Action {
        case appeared
        case tabSelected(Tab)
        case retryTapped
        case reloadReviewsRequested
        case editRequestHandled(Int)
        case reviews(MyReviewPostsReducer.Action)
        case courses(MyCoursePostsReducer.Action)
        case snackbarDismissed(String)
    }

    private enum EffectID { case snackbar }

    private let reviewsReducer: MyReviewPostsReducer
    private let coursesReducer: MyCoursePostsReducer

    init(
        reviewRepository: ReviewRepository,
        practiceRepository: PracticeRepository,
        courseRepository: CourseRepository
    ) {
        reviewsReducer = MyReviewPostsReducer(
            reviewRepository: reviewRepository,
            practiceRepository: practiceRepository
        )
        coursesReducer = MyCoursePostsReducer(courseRepository: courseRepository)
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            RodiAnalytics.track(.myActivityOpened(tab: state.selectedTab.analyticsName))
            return selectedTabAppeared(state: &state)

        case let .tabSelected(tab):
            guard state.selectedTab != tab else { return .none }
            state.selectedTab = tab
            RodiAnalytics.track(.myActivityOpened(tab: tab.analyticsName))
            return selectedTabAppeared(state: &state)

        case .retryTapped:
            return state.selectedTab == .courses
                ? coursesReducer.reduce(&state.courses, with: .retryRequested).map(Action.courses)
                : reviewsReducer.reduce(&state.reviews, with: .retryRequested).map(Action.reviews)

        case .reloadReviewsRequested:
            return reviewsReducer.reduce(&state.reviews, with: .reloadRequested).map(Action.reviews)

        case let .editRequestHandled(reviewID):
            guard state.pendingEditReviewID == reviewID else { return .none }
            state.pendingEditReviewID = nil
            return .none

        case let .reviews(action):
            let effect = reviewsReducer.reduce(&state.reviews, with: action)
            if case let .delegate(delegate) = action {
                return handleReviewDelegate(delegate, state: &state)
            }
            return effect.map(Action.reviews)

        case let .courses(action):
            let effect = coursesReducer.reduce(&state.courses, with: action)
            if case let .delegate(delegate) = action {
                return handleCourseDelegate(delegate, state: &state)
            }
            return effect.map(Action.courses)

        case let .snackbarDismissed(message):
            guard state.snackbarMessage == message else { return .none }
            state.snackbarMessage = nil
            return .none
        }
    }
}

private extension MyPostsReducer {
    func selectedTabAppeared(state: inout State) -> Effect<Action> {
        switch state.selectedTab {
        case .courses:
            return coursesReducer.reduce(&state.courses, with: .appeared).map(Action.courses)
        case .reviews:
            return reviewsReducer.reduce(&state.reviews, with: .appeared).map(Action.reviews)
        }
    }

    func handleReviewDelegate(
        _ delegate: MyReviewPostsReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case let .editingRequested(reviewID):
            state.pendingEditReviewID = reviewID
            return .none
        case .practiceRecordsRefreshRequested:
            state.practiceRecordsRefreshRequestID += 1
            return showSnackbarAndReloadReviews("후기를 삭제했습니다.", state: &state)
        case let .snackbarRequested(message):
            return presentSnackbar(message, state: &state)
        }
    }

    func handleCourseDelegate(
        _ delegate: MyCoursePostsReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case let .snackbarRequested(message):
            return showSnackbarAndReloadCourses(message, state: &state)
        }
    }

    func showSnackbarAndReloadReviews(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            await send(.reloadReviewsRequested)
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    func showSnackbarAndReloadCourses(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            await send(.courses(.retryRequested))
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }

    func presentSnackbar(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await send(.snackbarDismissed(message))
        }
        .cancelTask(id: EffectID.snackbar)
    }
}

private extension MyPostsTab {
    var analyticsName: String {
        switch self {
        case .courses: "courses"
        case .reviews: "reviews"
        }
    }
}
