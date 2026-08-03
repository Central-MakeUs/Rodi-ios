import Foundation

struct PlaceListItemDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let distanceFromMe: Int?
    let practiceTypes: [String]?
    let description: String?
    let distanceMeters: Int?
    let capacity: Int?
    let openTime: String?
}
