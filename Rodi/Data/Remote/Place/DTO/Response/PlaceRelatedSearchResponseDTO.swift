import Foundation

struct PlaceRelatedSearchDTO: Decodable {
    let regions: [String]
    let places: PlaceCursorPageDTO
}
