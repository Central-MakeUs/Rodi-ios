import Foundation

struct PlaceCursorPageDTO: Decodable {
    let items: [PlaceListItemDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}
