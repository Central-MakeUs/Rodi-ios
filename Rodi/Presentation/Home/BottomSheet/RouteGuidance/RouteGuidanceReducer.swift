import Foundation

/// 코스·주차장 상세가 공통으로 사용하는 외부 길안내의 화면 상태와 Effect를 소유한다.
/// 측정 저장·장소별 완료 정책은 부모 상세 reducer가 delegate로 처리한다.
@MainActor
struct RouteGuidanceReducer: Reducer {
    typealias State = RouteGuidanceState

    enum Action {
        case start(detail: PlaceDetail?, userLocation: RodiCoordinate?, hasLocationPermission: Bool)
        case appSelected(RouteGuidanceApp, rememberSelection: Bool)
        case installSelected(RouteGuidanceApp)
        case activeMeasurementEnded
        case routeOnlySelected
        case settingsReturned
        case dismiss
        case trackingPrepared(
            RouteGuidanceTrackingPreparation,
            request: RouteGuidanceFlowRequest,
            requestID: Int
        )
        case willOpen(
            request: RouteGuidanceFlowRequest,
            mode: PracticeMeasurementMode,
            measurementID: UUID,
            requestID: Int
        )
        case openFinished(
            RouteGuidanceResult,
            request: RouteGuidanceFlowRequest,
            measurementID: UUID,
            cancelTrackingOnFailure: Bool,
            requestID: Int
        )
        case installFinished(RouteGuidanceResult, requestID: Int)
        case delegate(Delegate)
    }

    enum Delegate {
        case willOpen(RouteGuidanceFlowRequest, mode: PracticeMeasurementMode, measurementID: UUID)
        case openFinished(RouteGuidanceResult, measurementID: UUID)
        case activeMeasurementEnded
        case showSnackbar(String)
    }

    private let flowService: RouteGuidanceFlowService
    private let effectID: String
    private let activeMeasurementFallbackName: String

    init(
        flowService: RouteGuidanceFlowService,
        effectID: String,
        activeMeasurementFallbackName: String
    ) {
        self.flowService = flowService
        self.effectID = effectID
        self.activeMeasurementFallbackName = activeMeasurementFallbackName
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case let .start(detail, userLocation, hasLocationPermission):
            guard hasLocationPermission else {
                return snackbar("위치 권한을 허용한 뒤 다시 시도해주세요.")
            }
            guard let detail, let userLocation else {
                return snackbar("현재 위치를 확인한 뒤 다시 시도해주세요.")
            }

            switch flowService.launchOption {
            case .open(let app):
                return continueGuidance(
                    .init(app: app, detail: detail, userLocation: userLocation),
                    state: &state
                )
            case .choose:
                state.request = .init(app: .kakaoMap, detail: detail, userLocation: userLocation)
                state.presentation = .chooseApp
            case .install:
                state.request = .init(app: .kakaoMap, detail: detail, userLocation: userLocation)
                state.presentation = .installApp
            }

        case let .appSelected(app, rememberSelection):
            guard let request = state.request else { return .none }
            if rememberSelection {
                flowService.savePreferredApp(app)
            }
            return continueGuidance(
                .init(app: app, detail: request.detail, userLocation: request.userLocation),
                state: &state
            )

        case .installSelected(let app):
            state.presentation = nil
            state.requestID += 1
            return installEffect(app: app, requestID: state.requestID)

        case .activeMeasurementEnded:
            guard let request = state.request else { return .none }
            flowService.cancelActiveMeasurement()
            state.presentation = nil
            state.request = nil
            return .run { send in
                await send(.delegate(.activeMeasurementEnded))
                await send(.start(
                    detail: request.detail,
                    userLocation: request.userLocation,
                    hasLocationPermission: true
                ))
            }

        case .routeOnlySelected:
            guard let request = state.request else { return .none }
            state.presentation = nil
            return openEffect(
                request: request,
                mode: .routeOnly,
                measurementID: UUID(),
                cancelTrackingOnFailure: false,
                state: &state
            )

        case .settingsReturned:
            guard let request = state.request else { return .none }
            state.presentation = nil
            if flowService.areLiveActivitiesEnabled {
                return continueGuidance(request, state: &state)
            }
            return openEffect(
                request: request,
                mode: .routeOnly,
                measurementID: UUID(),
                cancelTrackingOnFailure: false,
                state: &state
            )

        case .dismiss:
            state.presentation = nil
            state.request = nil
            state.isLaunching = false
            return .cancel(id: effectID)

        case let .trackingPrepared(preparation, request, requestID):
            guard requestID == state.requestID,
                  state.request?.detail.id == request.detail.id
            else {
                return .none
            }
            state.isLaunching = false

            switch preparation {
            case .started(let measurementID):
                return openEffect(
                    request: request,
                    mode: .gpsTracking,
                    measurementID: measurementID,
                    cancelTrackingOnFailure: true,
                    state: &state
                )
            case .authorizationRequested:
                return finish("위치 권한을 허용한 뒤 다시 연습하러 가기를 눌러주세요.", state: &state)
            case .reducedAccuracyRequested:
                return openRouteOnly(
                    request,
                    message: "정확한 위치를 허용하면 다음 길안내부터 연습 기록을 시작할 수 있어요.",
                    state: &state
                )
            case .unavailable(let message):
                return openRouteOnly(request, message: message, state: &state)
            }

        case let .willOpen(request, mode, measurementID, requestID):
            guard requestID == state.requestID,
                  state.request?.detail.id == request.detail.id
            else {
                return .none
            }
            return .send(.delegate(.willOpen(request, mode: mode, measurementID: measurementID)))

        case let .openFinished(result, request, measurementID, cancelTrackingOnFailure, requestID):
            guard requestID == state.requestID,
                  state.request?.detail.id == request.detail.id
            else {
                return .none
            }
            state.isLaunching = false
            state.request = nil
            if cancelTrackingOnFailure, case .openedApp = result {
                // 외부 앱 열기가 성공한 경우만 측정 session을 유지한다.
            } else if cancelTrackingOnFailure {
                flowService.cancelActiveMeasurement()
            }
            return .run { send in
                await send(.delegate(.openFinished(result, measurementID: measurementID)))
                if let message = result.userMessage {
                    await send(.delegate(.showSnackbar(message)))
                }
            }

        case let .installFinished(result, requestID):
            guard requestID == state.requestID else { return .none }
            return result.userMessage.map(snackbar) ?? .none

        case .delegate:
            return .none
        }

        return .none
    }
}

private extension RouteGuidanceReducer {
    func continueGuidance(
        _ request: RouteGuidanceFlowRequest,
        state: inout State
    ) -> Effect<Action> {
        state.request = request

        guard !flowService.hasActiveMeasurement else {
            state.presentation = .activeMeasurement(
                courseName: flowService.activeMeasurementName ?? activeMeasurementFallbackName
            )
            return .none
        }

        guard flowService.areLiveActivitiesEnabled else {
            state.presentation = .liveActivityPermission
            return .none
        }

        state.presentation = nil
        state.isLaunching = true
        state.requestID += 1
        let requestID = state.requestID
        let flowService = flowService
        return .run { send in
            await send(.trackingPrepared(
                await flowService.prepareTracking(for: request),
                request: request,
                requestID: requestID
            ))
        }
        .cancelTask(id: effectID)
    }

    func openRouteOnly(
        _ request: RouteGuidanceFlowRequest,
        message: String,
        state: inout State
    ) -> Effect<Action> {
        openEffect(
            request: request,
            mode: .routeOnly,
            measurementID: UUID(),
            cancelTrackingOnFailure: false,
            initialSnackbarMessage: message,
            state: &state
        )
    }

    func openEffect(
        request: RouteGuidanceFlowRequest,
        mode: PracticeMeasurementMode,
        measurementID: UUID,
        cancelTrackingOnFailure: Bool,
        initialSnackbarMessage: String? = nil,
        state: inout State
    ) -> Effect<Action> {
        state.isLaunching = true
        state.request = request
        state.requestID += 1
        let requestID = state.requestID
        let flowService = flowService

        return .run { send in
            if let initialSnackbarMessage {
                await send(.delegate(.showSnackbar(initialSnackbarMessage)))
            }
            await send(.willOpen(
                request: request,
                mode: mode,
                measurementID: measurementID,
                requestID: requestID
            ))
            await send(.openFinished(
                await flowService.open(request),
                request: request,
                measurementID: measurementID,
                cancelTrackingOnFailure: cancelTrackingOnFailure,
                requestID: requestID
            ))
        }
        .cancelTask(id: effectID)
    }

    func installEffect(app: RouteGuidanceApp, requestID: Int) -> Effect<Action> {
        let flowService = flowService
        return .run { send in
            await send(.installFinished(
                await flowService.openInstallPage(for: app),
                requestID: requestID
            ))
        }
        .cancelTask(id: effectID)
    }

    func finish(_ message: String, state: inout State) -> Effect<Action> {
        state.request = nil
        state.presentation = nil
        state.isLaunching = false
        return snackbar(message)
    }

    func snackbar(_ message: String) -> Effect<Action> {
        .send(.delegate(.showSnackbar(message)))
    }
}
