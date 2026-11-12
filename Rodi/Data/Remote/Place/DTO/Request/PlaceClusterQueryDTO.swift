import Foundation

struct PlaceClusterQueryDTO: Encodable {
    let swLat: Double
    let swLng: Double
    let neLat: Double
    let neLng: Double
    let practiceTypes: [String]?
}
