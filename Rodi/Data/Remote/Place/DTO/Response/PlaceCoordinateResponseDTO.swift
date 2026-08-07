import Foundation

struct PlaceCoordinateDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
}
