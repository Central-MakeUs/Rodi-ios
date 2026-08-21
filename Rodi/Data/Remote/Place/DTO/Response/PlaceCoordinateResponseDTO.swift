import Foundation

struct PlaceCoordinateDTO: Decodable {
    let id: Int64
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
}
