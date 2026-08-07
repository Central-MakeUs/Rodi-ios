import Foundation

struct PlaceRelatedSearchDTO: Decodable {
    let regions: [String]
    let places: PlaceRelatedSearchCursorPageDTO
}

/// `/api/v1/places/related-search`의 장소 자동완성 항목입니다.
/// 일반 장소 목록과 달리 장소 유형, 주소, 좌표를 포함하지 않습니다.
struct PlaceRelatedSearchItemDTO: Decodable {
    let placeID: Int
    let name: String
    let region: String

    private enum CodingKeys: String, CodingKey {
        case placeID = "placeId"
        case name
        case region
    }
}

struct PlaceRelatedSearchCursorPageDTO: Decodable {
    let items: [PlaceRelatedSearchItemDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}
