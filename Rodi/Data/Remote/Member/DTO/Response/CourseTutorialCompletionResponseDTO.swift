import Foundation

/// `PATCH /api/v1/members/me/course-tutorial`의 완료 응답 계약.
struct CourseTutorialCompletionResponseDTO: Decodable {
    let courseTutorialCompletedAt: String?
}
