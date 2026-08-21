import Foundation

/// 길안내 시도 한 건의 UI·최신성 상태다.
///
/// 코스와 주차장 상세는 측정 저장 정책만 다르고, 앱 선택과 외부 앱 실행의
/// 화면 상태는 같으므로 이 값을 함께 사용한다.
struct RouteGuidanceState {
    var presentation: RouteGuidanceFlowPresentation?
    var request: RouteGuidanceFlowRequest?
    var requestID = 0
    var isLaunching = false
}
