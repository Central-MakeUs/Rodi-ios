import Foundation

struct MemberProfileResponseDTO: Decodable {
    let nickname: String
    let level: String
    let recommendationTags: [String]
    let drivingGoal: String?
    let savedPlaceCount: Int64
    let levelProgress: LevelProgressResponseDTO?
}

struct LevelProgressResponseDTO: Decodable {
    let totalDistanceKm: Double
    let currentLevelStartKm: Double
    let nextLevelKm: Double?
    let progressPercent: Int
}
