import Foundation

struct PlaceDetailDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let practiceTypes: [String]?
    let bookmarkCount: Int?
    let isBookmarked: Bool?
    let course: PlaceCourseDetailDTO?
    let parking: PlaceParkingDetailDTO?
}
