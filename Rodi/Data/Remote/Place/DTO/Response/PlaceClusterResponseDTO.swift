import Foundation

struct PlaceClusterResponseDTO: Decodable {
    let places: [PlaceCoordinateDTO]
    let levels: [PlaceClusterLevelDTO]
}

struct PlaceClusterLevelDTO: Decodable {
    let minLngSpan: Double
    let maxLngSpan: Double?
    let clusters: [PlaceClusterDTO]
    let placeIds: [Int64]
}

struct PlaceClusterDTO: Decodable {
    let lat: Double
    let lng: Double
    let count: Int
    let bounds: PlaceClusterBoundsDTO
}

struct PlaceClusterBoundsDTO: Decodable {
    let swLat: Double
    let swLng: Double
    let neLat: Double
    let neLng: Double
}
