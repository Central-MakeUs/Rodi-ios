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
    
    init(
        _ value: MemberOnboardingSubmission
    ) {
        drivingPeriod = value.drivingPeriod.rawValue
        recentFrequency = value.recentFrequency?.rawValue
        roadExperiences = value.roadExperiences.isEmpty
            ? nil
            : value.roadExperiences.map(\.rawValue)
        
        soloDrivingRange = value.soloDrivingRange?.rawValue
        soloParkingLevel = value.soloParkingLevel?.rawValue
        level = value.level.rawValue
        practiceTypes = value.practiceTypes.isEmpty
            ? nil
            : value.practiceTypes.map(\.rawValue)
        
        carType = value.carType?.rawValue; drivingGoal = value.drivingGoal
    }
}
