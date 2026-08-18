import Foundation

struct CourseDetailBottomSheetReducer: Reducer {
    enum Presentation: Equatable { case sheet, expandedDetail }
    typealias ReviewPageState = CourseReviewReducer.PageState
    typealias ReviewSummaryState = CourseReviewReducer.SummaryState

    struct State {
        var detail: PlaceDetail?
        var routeOverlay: RodiRouteOverlay?
        var isRouteLoading = false
        var routeStatusMessage: String?
        var isBookmarkUpdating = false
        var presentation: Presentation = .sheet
        var isRouteTimelineExpanded = false
        var reviews = CourseReviewReducer.State()
    }

    enum Action {
        case present(PlaceDetail, source: String)
        case dismiss
        case cancelRoadRouteLoading
        case toggleBookmark
        case bookmarkUpdated(placeID: Int, isBookmarked: Bool, source: String)
        case bookmarkFailed(previousDetail: PlaceDetail, message: String)
        case roadRouteLoaded(courseID: Int, path: [RodiCoordinate])
        case roadRouteFailed(courseID: Int, message: String?)
        case externalRouteGuidanceWillOpen(
            placeID: Int,
            mode: PracticeMeasurementMode,
            measurementID: UUID,
            externalHandoffAt: Date
        )
        case externalRouteGuidanceFailed(measurementID: UUID)
        case activeMeasurementEnded
        case expandRequested
        case collapseRequested
        case routeTimelineToggled
        case reviews(CourseReviewReducer.Action)
        case delegate(Delegate)
    }
    enum Delegate { case dismissed, routeOverlayChanged(RodiRouteOverlay?), requestAuthentication, showSnackbar(String), reviewWritingRequested(ReviewWriteRequest), reviewEditingRequested(Int) }
    private let placeRepository: PlaceRepository
    private let practiceMeasurementStore: PracticeMeasurementStoring
    private let hasActiveSession: () -> Bool
    private let reviewsReducer: CourseReviewReducer
    private let onDelegate: (Delegate) -> Void

    init(placeRepository: PlaceRepository, memberRepository: MemberRepository, practiceRepository: PracticeRepository, reviewRepository: ReviewRepository, practiceMeasurementStore: PracticeMeasurementStoring, hasActiveSession: @escaping () -> Bool, onDelegate: @escaping (Delegate) -> Void = { _ in }) {
        self.placeRepository = placeRepository
        self.practiceMeasurementStore = practiceMeasurementStore
        self.hasActiveSession = hasActiveSession
        self.onDelegate = onDelegate
        reviewsReducer = .init(repository: reviewRepository, memberRepository: memberRepository, hasActiveSession: hasActiveSession)
    }
}

// MARK: - Reduce
extension CourseDetailBottomSheetReducer {
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present(let detail, _):
            guard detail.type == .course else { return .none }
            state = .init(detail: detail)
            RodiAnalytics.track(.placeDetailOpened(source: "home", placeType: detail.type.rawValue))
            return configureRoute(for: .init(placeDetail: detail), state: &state)
        case .dismiss:
            guard state.detail != nil else { return .none }
            state = .init()
            return .run { send in
                await send(.cancelRoadRouteLoading)
                await send(.reviews(.report(.reset)))
                await send(.reviews(.block(.reset)))
                await send(.reviews(.reset))
                await send(.delegate(.dismissed))
            }
        case .cancelRoadRouteLoading: return .cancel(id: BottomSheetEffectID.routeLoading)
        case .toggleBookmark:
            guard let detail = state.detail, !state.isBookmarkUpdating else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            let previous = detail; let bookmarked = !detail.isBookmarked
            state.detail = detail.updatingBookmark(isBookmarked: bookmarked); state.isBookmarkUpdating = true
            return bookmarkEffect(placeID: detail.id, isBookmarked: bookmarked, previous: previous)
        case let .bookmarkUpdated(placeID, bookmarked, source):
            guard state.detail?.id == placeID else { return .none }
            state.detail = state.detail?.updatingBookmark(isBookmarked: bookmarked); state.isBookmarkUpdating = false
            RodiAnalytics.track(.bookmarkUpdated(isBookmarked: bookmarked, source: source, placeType: PlaceType.course.rawValue))
            return .none
        case .bookmarkFailed(let previous, let message):
            guard state.detail?.id == previous.id else { return .none }; state.detail = previous; state.isBookmarkUpdating = false
            return .send(.delegate(.showSnackbar(message)))
        case .roadRouteLoaded(let courseID, let path):
            guard let overlay = state.routeOverlay, overlay.courseID == courseID else { return .none }
            state.routeOverlay = .init(courseID: courseID, points: overlay.points, path: path, isRoadRoute: true); state.isRouteLoading = false; state.routeStatusMessage = nil
            return .send(.delegate(.routeOverlayChanged(state.routeOverlay)))
        case .roadRouteFailed(let courseID, let message):
            guard state.routeOverlay?.courseID == courseID else { return .none }; state.isRouteLoading = false; state.routeStatusMessage = message
            return .send(.delegate(.routeOverlayChanged(state.routeOverlay)))
        case let .externalRouteGuidanceWillOpen(placeID, mode, measurementID, externalHandoffAt):
            guard state.detail?.id == placeID, let name = state.detail?.name else { return .none }
            let measurement = PracticeMeasurement(
                id: measurementID,
                placeID: placeID,
                placeName: name,
                mode: mode,
                externalHandoffAt: externalHandoffAt,
                status: mode == .gpsTracking ? .tracking : .awaitingReturn
            )
            practiceMeasurementStore.save(measurement)
            PracticeTrackingService.shared.synchronizeCompletedSessionCertificationIfNeeded()

        case let .externalRouteGuidanceFailed(measurementID):
            guard practiceMeasurementStore.load()?.id == measurementID else { return .none }
            practiceMeasurementStore.clear()

        case .activeMeasurementEnded:
            practiceMeasurementStore.clear()
        case .expandRequested:
            guard let placeID = state.detail?.id, state.presentation == .sheet else { return .none }
            state.presentation = .expandedDetail
            return reviewsReducer.reduce(&state.reviews, with: .start(placeID: placeID)).map(Action.reviews)
        case .collapseRequested:
            guard state.presentation == .expandedDetail else { return .none }; state.presentation = .sheet
        case .routeTimelineToggled:
            guard state.presentation == .expandedDetail else { return .none }; state.isRouteTimelineExpanded.toggle()
        case .reviews(let child):
            if case .delegate(let delegate) = child { return reduceReviewsDelegate(delegate, state: &state) }
            return reviewsReducer.reduce(&state.reviews, with: child).map(Action.reviews)
        case .delegate(let delegate): onDelegate(delegate)
        }
        return .none
    }
}

// MARK: - Child Delegate
private extension CourseDetailBottomSheetReducer {
    func reduceReviewsDelegate(_ delegate: CourseReviewReducer.Delegate, state: inout State) -> Effect<Action> {
        switch delegate {
        case .writingRequested:
            guard let detail = state.detail else { return .none }
            return .send(.delegate(.reviewWritingRequested(.init(placeID: detail.id, placeName: detail.name))))
        case .editingRequested(let reviewID):
            return .send(.delegate(.reviewEditingRequested(reviewID)))
        case .requestAuthentication: return .send(.delegate(.requestAuthentication))
        case .showSnackbar(let message): return .send(.delegate(.showSnackbar(message)))
        }
    }
}

// MARK: - Effect
private extension CourseDetailBottomSheetReducer {
    func configureRoute(for item: RodiCourseItem, state: inout State) -> Effect<Action> {
        let points = item.routeOverlayPoints
        guard points.count >= 2 else { state.routeOverlay = nil; state.routeStatusMessage = "경로 좌표가 아직 준비되지 않았어요."; return .cancel(id: BottomSheetEffectID.routeLoading) }
        state.routeOverlay = .init(courseID: item.id, points: points, path: points.map(\.coordinate), isRoadRoute: false); state.isRouteLoading = true
        return .run { send in
            do { await send(.roadRouteLoaded(courseID: item.id, path: try await KakaoDirectionsService().fetchRoute(points: points))) }
            catch is CancellationError { }
            catch let error as KakaoDirectionsError { await send(.roadRouteFailed(courseID: item.id, message: error.fallbackMessage)) }
            catch { await send(.roadRouteFailed(courseID: item.id, message: "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요.")) }
        }.cancelTask(id: BottomSheetEffectID.routeLoading)
    }
    func bookmarkEffect(placeID: Int, isBookmarked: Bool, previous: PlaceDetail) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in do { if isBookmarked { try await repository.bookmark(placeID: placeID) } else { try await repository.unbookmark(placeID: placeID) }; await send(.bookmarkUpdated(placeID: placeID, isBookmarked: isBookmarked, source: "home")) } catch is CancellationError {} catch { await send(.bookmarkFailed(previousDetail: previous, message: "북마크를 \(isBookmarked ? "저장" : "해제")하지 못했어요.")) } }.cancelTask(id: BottomSheetEffectID.bookmarkUpdating)
    }
}
