import Foundation

/// 장소 조회 endpoint가 사용하는 wire query 계약 모음.
struct PlaceListQueryDTO: Encodable {
    let southWestLatitude: Double
    let southWestLongitude: Double
    let northEastLatitude: Double
    let northEastLongitude: Double
    let currentLatitude: Double
    let currentLongitude: Double
    let size: Int
    let cursor: String?
}

struct PlaceSearchQueryDTO: Encodable {
    let keyword: String
    let currentLatitude: Double
    let currentLongitude: Double
    let size: Int
    let cursor: String?
}

struct PlaceRelatedSearchQueryDTO: Encodable {
    let keyword: String
    let size: Int
    let cursor: String?
}

struct PlaceBookmarkListQueryDTO: Encodable {
    let size: Int
    let cursor: String?
}
