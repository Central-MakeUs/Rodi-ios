import Foundation

struct MyPracticeCursorPageResponseDTO: Decodable {
    let items: [MyPracticeItemResponseDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int64?
}

struct MyPracticeItemResponseDTO: Decodable {
    let practiceId: Int64
    let placeId: Int64
    let placeName: String
    let practiceTypes: [String]
    let status: String
    let visitCount: Int
    let lastActivityAt: String?
    let hasReview: Bool
    let isDeleted: Bool?
}
