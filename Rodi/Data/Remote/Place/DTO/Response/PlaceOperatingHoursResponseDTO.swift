import Foundation

struct PlaceOperatingHoursDTO: Decodable {
    let weekday: String?
    let saturday: String?
    let holiday: String?
}
