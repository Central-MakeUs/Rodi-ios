import Foundation

/// `GET /api/v1/members/me/practices`의 wire query 계약.
struct MyPracticeListQueryDTO: Encodable {
    let size: Int
    let cursor: String?
}
