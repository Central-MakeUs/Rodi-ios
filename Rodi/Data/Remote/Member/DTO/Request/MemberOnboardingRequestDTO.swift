import Foundation

struct MemberOnboardingRequestDTO: Encodable {
    let drivingPeriod: String
    let recentFrequency: String?
    let roadExperiences: [String]?
    let soloDrivingRange: String?
    let soloParkingLevel: String?
    let level: String; let practiceTypes: [String]?
    let carType: String?
    let drivingGoal: String?
    
}
