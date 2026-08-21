import Foundation

/// `GET /api/v1/members/me/blocks`의 wire query 계약.
struct BlockedMemberListQueryDTO: Encodable {
    let size: Int
    let cursor: String?
}
