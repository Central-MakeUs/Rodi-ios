import Foundation

/// `GET /api/v1/members/me/courses` 응답 계약.
struct MyCourseCursorPageResponseDTO: Decodable {
    let items: [MyCourseItemResponseDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int64?
}

struct MyCourseItemResponseDTO: Decodable {
    let courseId: Int64
    let name: String
    let approvalStatus: String
    let createdAt: String
}
