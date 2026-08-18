import Foundation

struct MyReviewCursorPageResponseDTO: Decodable {
    let items: [MyReviewItemResponseDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int64?
}

struct MyReviewItemResponseDTO: Decodable {
    let reviewId: Int64
    let placeId: Int64
    let placeName: String
    // Swagger permits a null review body when the author submitted no optional content.
    let content: String?
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: String
}
