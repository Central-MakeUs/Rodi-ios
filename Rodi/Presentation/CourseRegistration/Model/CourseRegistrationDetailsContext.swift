import Foundation

/// 상세정보 입력과 등록 요청에 필요한, 지도 선택 단계의 확정 결과다.
/// 상세정보 Reducer는 이 값을 읽기만 하며 지도 선택 상태를 변경하지 않는다.
struct CourseRegistrationDetailsContext: Equatable {
    let waypoints: [CourseRegistrationWaypoint]
    let selectedPlaces: [CourseRegistrationInputTarget: CourseRegistrationSelectedPlace]
    let routePath: [RodiCoordinate]
}
