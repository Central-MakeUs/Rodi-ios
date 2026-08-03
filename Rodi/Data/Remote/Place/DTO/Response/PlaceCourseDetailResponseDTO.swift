import Foundation

struct PlaceCourseDetailDTO: Decodable {
    let description: String?
    let cautions: [String]?
    let distanceMeters: Int?
    let waypoints: [PlaceWaypointDTO]?
}
