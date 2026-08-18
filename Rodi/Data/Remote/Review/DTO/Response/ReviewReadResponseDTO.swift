import Foundation

struct ReviewDetailResponseDTO: Decodable {
    let reviewId: Int64
    let placeId: Int64
    let placeName: String
    let isRecommended: Bool
    let difficulty: String
    let congestion: String
    let practiceMethod: String
    let content: String?
    let caution: String?
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: String
}

struct ReviewSummaryResponseDTO: Decodable {
    let level: String?
    let levelReviewCount: Int64
    let totalReviewCount: Int64
    let topDifficulty: ReviewTopDifficultyDTO?
    let recommendCount: Int64
    let notRecommendCount: Int64
    let difficultyCounts: [String: Int64]
    let levelCounts: [String: Int64]
}

struct ReviewTopDifficultyDTO: Decodable {
    let difficulty: String
    let count: Int64
}

struct ReviewCursorPageResponseDTO: Decodable {
    let items: [ReviewItemResponseDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int64?
}

struct ReviewItemResponseDTO: Decodable {
    let reviewId: Int64
    let memberId: Int64
    let nickname: String?
    let practiceMethod: String
    // Swagger permits a null review body when the author submitted no optional content.
    let content: String?
    let isMine: Bool
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: String
}
