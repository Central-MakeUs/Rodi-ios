//
//  CourseDetailBottomSheetReducer.swift
//  Rodi
//

import Foundation

struct CourseDetailBottomSheetReducer: Reducer {
    struct State {
        var detail: PlaceDetail?
        var routeOverlay: RodiRouteOverlay?
        var isRouteLoading = false
        var routeStatusMessage: String?
        var isBookmarkUpdating = false
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
        case delegate(Delegate)
    }

    enum Delegate {
        case dismissed
        case routeOverlayChanged(RodiRouteOverlay?)
        case requestAuthentication
        case showSnackbar(String)
    }

    private let placeRepository: PlaceRepository
    private let hasActiveSession: () -> Bool
    private let onDelegate: (Delegate) -> Void

    init(placeRepository: PlaceRepository,
         hasActiveSession: @escaping () -> Bool,
         onDelegate: @escaping (Delegate) -> Void = { _ in }) {
        self.placeRepository = placeRepository
        self.hasActiveSession = hasActiveSession
        self.onDelegate = onDelegate
    }
}


// MARK: - Core Logics
extension CourseDetailBottomSheetReducer {
    
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present(let detail, _):
            guard detail.type == .course else { return .none }
            state.detail = detail
            state.isBookmarkUpdating = false
            state.routeStatusMessage = nil
            let item = RodiCourseItem(placeDetail: detail)
            RodiAnalytics.track(.placeDetailOpened(source: "home", placeType: detail.type.rawValue))
            let effect = configureRoute(for: item, state: &state)
            return effect

        case .dismiss:
            guard state.detail != nil else { return .none }
            state = State()
            return .run { send in
                await send(.cancelRoadRouteLoading)
                await send(.delegate(.dismissed))
            }

        case .cancelRoadRouteLoading:
            return .cancel(id: BottomSheetEffectID.routeLoading)

        case .toggleBookmark:
            guard let detail = state.detail, !state.isBookmarkUpdating else { return .none }
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            let previousDetail = detail
            let isBookmarked = !detail.isBookmarked
            state.detail = detail.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = true
            return updateBookmarkEffect(placeID: detail.id, isBookmarked: isBookmarked, previousDetail: previousDetail)

        case .bookmarkUpdated(let id, let isBookmarked, let source):
            guard state.detail?.id == id else { return .none }
            state.detail = state.detail?.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = false
            RodiAnalytics.track(.bookmarkUpdated(isBookmarked: isBookmarked, source: source, placeType: PlaceType.course.rawValue))
            return .send(.delegate(.showSnackbar(isBookmarked ? "북마크를 저장했어요." : "북마크를 해제했어요.")))

        case .bookmarkFailed(let previousDetail, let message):
            guard state.detail?.id == previousDetail.id else { return .none }
            state.detail = previousDetail
            state.isBookmarkUpdating = false
            return .send(.delegate(.showSnackbar(message)))

        case .roadRouteLoaded(let courseID, let path):
            guard let overlay = state.routeOverlay, overlay.courseID == courseID else { return .none }
            state.routeOverlay = RodiRouteOverlay(courseID: courseID, points: overlay.points, path: path, isRoadRoute: true)
            state.isRouteLoading = false
            state.routeStatusMessage = nil
            return .send(.delegate(.routeOverlayChanged(state.routeOverlay)))

        case .roadRouteFailed(let courseID, let message):
            guard state.routeOverlay?.courseID == courseID else { return .none }
            state.isRouteLoading = false
            state.routeStatusMessage = message
            return .send(.delegate(.routeOverlayChanged(state.routeOverlay)))

        case .delegate(let delegate):
            onDelegate(delegate)
        }
        
        return .none
    }

    private func configureRoute(for item: RodiCourseItem, state: inout State) -> Effect<Action> {
        let points = item.routeOverlayPoints
        guard points.count >= 2 else {
            state.routeOverlay = nil
            state.isRouteLoading = false
            state.routeStatusMessage = "경로 좌표가 아직 준비되지 않았어요."
            return .cancel(id: BottomSheetEffectID.routeLoading)
        }
        state.routeOverlay = RodiRouteOverlay(courseID: item.id, points: points, path: points.map(\.coordinate), isRoadRoute: false)
        state.isRouteLoading = true
        return loadRoadRouteEffect(courseID: item.id, points: points)
    }

    private func updateBookmarkEffect(placeID: Int, isBookmarked: Bool, previousDetail: PlaceDetail) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                if isBookmarked { try await repository.bookmark(placeID: placeID) }
                else { try await repository.unbookmark(placeID: placeID) }
                await send(.bookmarkUpdated(placeID: placeID, isBookmarked: isBookmarked, source: "home"))
            } catch is CancellationError {
                return
            } catch {
                if requiresAuthentication(error) { await send(.delegate(.requestAuthentication)) }
                else { await send(.bookmarkFailed(previousDetail: previousDetail, message: "북마크를 \(isBookmarked ? "저장" : "해제")하지 못했어요.")) }
            }
        }
        .cancelTask(id: BottomSheetEffectID.bookmarkUpdating)
    }

    private func loadRoadRouteEffect(courseID: Int, points: [RodiRouteOverlayPoint]) -> Effect<Action> {
        .run { send in
            do {
                let path = try await KakaoDirectionsService().fetchRoute(points: points)
                await send(.roadRouteLoaded(courseID: courseID, path: path))
            } catch is CancellationError {
                return
            } catch let error as KakaoDirectionsError {
                await send(.roadRouteFailed(courseID: courseID, message: error.fallbackMessage))
            } catch {
                await send(.roadRouteFailed(courseID: courseID, message: "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요."))
            }
        }
        .cancelTask(id: BottomSheetEffectID.routeLoading)
    }

    private func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }
}
