import Foundation

/// `POST /api/v1/courses` 요청 계약.
/// 실제 등록 화면·API target 연결은 다음 작업 범위에서 진행한다.
struct CourseRegisterRequestDTO: Encodable {
    let name: String
    let address: String
    let distanceMeters: Int
    let waypoints: [CourseWaypointRequestDTO]
    let practiceTypes: [String]
    let description: String
    let caution: String
}

struct CourseWaypointRequestDTO: Encodable {
    let type: String
    let lat: Double
    let lng: Double
    let name: String
}
