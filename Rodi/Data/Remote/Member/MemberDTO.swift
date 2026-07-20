//
//  MemberDTO.swift
//  Rodi
//

import Foundation

struct MemberOnboardingRequestDTO: Encodable {
    let drivingPeriod: String
    let recentFrequency: String?
    let roadExperiences: [String]?
    let soloDrivingRange: String?
    let soloParkingLevel: String?
    let level: String
    let practiceTypes: [String]?
    let carType: String?
    let drivingGoal: String?

    init(_ submission: MemberOnboardingSubmission) {
        drivingPeriod = submission.drivingPeriod.rawValue
        recentFrequency = submission.recentFrequency?.rawValue
        roadExperiences = submission.roadExperiences.isEmpty ? nil : submission.roadExperiences.map(\.rawValue)
        soloDrivingRange = submission.soloDrivingRange?.rawValue
        soloParkingLevel = submission.soloParkingLevel?.rawValue
        level = submission.level.rawValue
        practiceTypes = submission.practiceTypes.isEmpty ? nil : submission.practiceTypes.map(\.rawValue)
        carType = submission.carType?.rawValue
        drivingGoal = submission.drivingGoal
    }
}
