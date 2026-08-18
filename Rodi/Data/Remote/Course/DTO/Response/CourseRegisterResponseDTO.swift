import Foundation

/// `POST /api/v1/courses` 응답 계약.
struct CourseRegisterResponseDTO: Decodable {
    let courseId: Int64
    let approvalStatus: String
}
