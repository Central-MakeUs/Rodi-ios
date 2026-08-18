import Foundation

/// `GET /api/v1/members/me/courses`의 선택 query 계약.
/// `status`는 PENDING, APPROVED, REJECTED 중 하나이며 생략하면 전체를 조회한다.
struct MyCourseListQueryDTO: Encodable {
    let status: String?
    let size: Int?
    let cursor: String?
}
