//
//  ParkingDetailBottomSheetReducer.swift
//  Rodi
//

import Foundation

struct ParkingDetailBottomSheetReducer: Reducer {
    struct State {
        var detail: PlaceDetail?
        var isBookmarkUpdating = false
        var routeGuidance = RouteGuidanceReducer.State()

        var routeGuidancePresentation: RouteGuidanceFlowPresentation? {
            routeGuidance.presentation
        }

        var isRouteGuidanceLaunching: Bool {
            get { routeGuidance.isLaunching }
            set { routeGuidance.isLaunching = newValue }
        }
    }

    enum Action {
        case present(PlaceDetail, source: String)
        case dismiss
        case reset
        case toggleBookmark
        case bookmarkUpdated(placeID: Int, isBookmarked: Bool, source: String)
        case bookmarkFailed(previousDetail: PlaceDetail, message: String)
        case routeGuidanceTapped(userLocation: RodiCoordinate?, hasLocationPermission: Bool)
        case routeGuidanceAppSelected(RouteGuidanceApp, rememberSelection: Bool)
        case routeGuidanceInstallSelected(RouteGuidanceApp)
        case routeGuidanceActiveMeasurementEnded
        case routeGuidanceRouteOnlySelected
        case routeGuidanceSettingsReturned
        case routeGuidanceDismissed
        case routeGuidance(RouteGuidanceReducer.Action)
        case delegate(Delegate)
    }

    enum Delegate {
        case dismissed
        case focusMap(RodiCoordinate)
        case requestAuthentication
        case showSnackbar(String)
    }

    private let placeRepository: PlaceRepository
    private let practiceMeasurementStore: PracticeMeasurementStoring
    private let drivePracticeService: DrivePracticeService
    private let hasActiveSession: () -> Bool
    private let routeGuidanceReducer: RouteGuidanceReducer
    private let onDelegate: (Delegate) -> Void

    init(placeRepository: PlaceRepository,
         memberRepository: MemberRepository,
         practiceMeasurementStore: PracticeMeasurementStoring,
         drivePracticeService: DrivePracticeService,
         routeGuidanceService: RouteGuidanceService,
         hasActiveSession: @escaping () -> Bool,
         onDelegate: @escaping (Delegate) -> Void = { _ in }) {
        self.placeRepository = placeRepository
        self.practiceMeasurementStore = practiceMeasurementStore
        self.drivePracticeService = drivePracticeService
        self.hasActiveSession = hasActiveSession
        routeGuidanceReducer = .init(
            flowService: .init(
                memberRepository: memberRepository,
                drivePracticeService: drivePracticeService,
                directionsService: .init(),
                routeGuidanceService: routeGuidanceService
            ),
            effectID: BottomSheetEffectID.parkingRouteGuidance,
            activeMeasurementFallbackName: "현재 연습 장소"
        )
        self.onDelegate = onDelegate
    }
}


// MARK: - Core Logics
extension ParkingDetailBottomSheetReducer {

    func reduceRouteGuidance(
        _ state: inout State,
        action: RouteGuidanceReducer.Action
    ) -> Effect<Action> {
        if case .delegate(let delegate) = action {
            return reduceRouteGuidanceDelegate(delegate, state: &state)
        }
        return routeGuidanceReducer
            .reduce(&state.routeGuidance, with: action)
            .map(Action.routeGuidance)
    }

    func reduceRouteGuidanceDelegate(
        _ delegate: RouteGuidanceReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case let .willOpen(request, mode, measurementID):
            practiceMeasurementStore.save(.init(
                id: measurementID,
                placeID: request.detail.id,
                placeName: request.detail.name,
                placeType: .parking,
                mode: mode,
                externalHandoffAt: .now,
                status: mode == .gpsTracking ? .tracking : .awaitingReturn
            ))
            drivePracticeService.synchronizeCompletedSessionCertificationIfNeeded()

        case let .openFinished(result, measurementID):
            if case .openedApp = result {
                // 측정 후보는 외부 앱 전환 전에 저장했다.
            } else if practiceMeasurementStore.load()?.id == measurementID {
                practiceMeasurementStore.clear()
            }

        case .activeMeasurementEnded:
            practiceMeasurementStore.clear()

        case let .showSnackbar(message):
            return .send(.delegate(.showSnackbar(message)))
        }
        return .none
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present(let detail, _):
            guard detail.type == .parking else { return .none }
            state.detail = detail
            state.isBookmarkUpdating = false
            RodiAnalytics.track(.placeDetailOpened(source: "home", placeType: detail.type.rawValue))
            return .send(.delegate(.focusMap(RodiCoordinate(latitude: detail.latitude, longitude: detail.longitude))))

        case .dismiss:
            guard state.detail != nil else { return .none }
            state = State()
            return .run { send in
                await send(.routeGuidanceDismissed)
                await send(.delegate(.dismissed))
            }

        case .reset:
            state = .init()
            return .send(.routeGuidanceDismissed)

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
            RodiAnalytics.track(.bookmarkUpdated(isBookmarked: isBookmarked, source: source, placeType: PlaceType.parking.rawValue))
            return .none

        case .bookmarkFailed(let previousDetail, let message):
            guard state.detail?.id == previousDetail.id else { return .none }
            state.detail = previousDetail
            state.isBookmarkUpdating = false
            return .send(.delegate(.showSnackbar(message)))

        case .routeGuidanceTapped(let userLocation, let hasLocationPermission):
            return reduceRouteGuidance(
                &state,
                action: .start(
                    detail: state.detail,
                    userLocation: userLocation,
                    hasLocationPermission: hasLocationPermission
                )
            )

        case .routeGuidanceAppSelected(let app, let rememberSelection):
            return reduceRouteGuidance(&state, action: .appSelected(app, rememberSelection: rememberSelection))

        case .routeGuidanceInstallSelected(let app):
            return reduceRouteGuidance(&state, action: .installSelected(app))

        case .routeGuidanceActiveMeasurementEnded:
            return reduceRouteGuidance(&state, action: .activeMeasurementEnded)

        case .routeGuidanceRouteOnlySelected:
            return reduceRouteGuidance(&state, action: .routeOnlySelected)

        case .routeGuidanceSettingsReturned:
            return reduceRouteGuidance(&state, action: .settingsReturned)

        case .routeGuidanceDismissed:
            return reduceRouteGuidance(&state, action: .dismiss)

        case .routeGuidance(let child):
            return reduceRouteGuidance(&state, action: child)

        case .delegate(let delegate):
            onDelegate(delegate)
        }
        return .none
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

    private func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401): true
        case .apiError(let code, _, _): code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default: false
        }
    }
}
