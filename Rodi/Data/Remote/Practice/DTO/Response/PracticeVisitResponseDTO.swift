import Foundation

struct PracticeVisitResponseDTO: Decodable {
    let visitCount: Int
    let addedCertifiedDistanceMeters: Int
    let requiredDistanceMeters: Int
    let isCertifiedNow: Bool
    let totalDistanceKm: Double
    let levelUp: Bool
    let newLevel: String?
}
