import Foundation

struct MemberProfileResponseDTO: Decodable {
    let nickname: String
    let level: String
    let recommendationTags: [String]
    let drivingGoal: String?
    let savedPlaceCount: Int
}
