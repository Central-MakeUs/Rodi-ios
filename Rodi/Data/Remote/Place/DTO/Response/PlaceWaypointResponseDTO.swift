import Foundation

struct PlaceWaypointDTO: Decodable {
    let type: String
    let sequence: Int
    let lat: Double
    let lng: Double
    let name: String?
}
