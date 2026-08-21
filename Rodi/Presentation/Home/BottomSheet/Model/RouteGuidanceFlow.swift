import Foundation

/// 길안내 화면이 표시할 일시적 상태다. 실제 외부 앱 실행과 측정 시작은 reducer Effect가 소유한다.
enum RouteGuidanceFlowPresentation: Equatable {
    case chooseApp
    case installApp
    case activeMeasurement(courseName: String)
    case liveActivityPermission
}

/// 한 번의 길안내 시도에 필요한 화면 입력값이다.
struct RouteGuidanceFlowRequest {
    let app: RouteGuidanceApp
    let detail: PlaceDetail
    let userLocation: RodiCoordinate
}

enum RouteGuidanceTrackingPreparation {
    case started(measurementID: UUID)
    case authorizationRequested
    case reducedAccuracyRequested
    case unavailable(String)
}
