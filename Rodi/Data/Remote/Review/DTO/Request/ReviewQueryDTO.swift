import Foundation

/// 후기 조회 endpoint가 사용하는 wire query 계약 모음.
struct ReviewSummaryQueryDTO: Encodable {
    let level: String?
}

struct PlaceReviewListQueryDTO: Encodable {
    let level: String?
    let size: Int
    let cursor: String?
}

struct MyReviewListQueryDTO: Encodable {
    let size: Int
    let cursor: String?
}
