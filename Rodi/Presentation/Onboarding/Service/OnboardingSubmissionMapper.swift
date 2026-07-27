//
//  OnboardingSubmissionMapper.swift
//  Rodi
//

import Foundation

enum OnboardingSubmissionMapper {
    static func make(
        drivingExperience: OnboardingDrivingExperienceReducer.Answers,
        preferences: OnboardingOptionalDrivingPreferenceReducer.Preferences,
        drivingGoal: String
    ) -> MemberOnboardingSubmission? {
        guard let drivingPeriod = drivingExperience.licenseDrivingPeriod?.memberDrivingPeriod else {
            return nil
        }

        let baseSubmission = MemberOnboardingSubmission(
            drivingPeriod: drivingPeriod,
            recentFrequency: drivingExperience.recentDrivingFrequency?.memberRecentFrequency,
            roadExperiences: drivingExperience.selectedRoadDrivingExperiences.map(\.memberRoadExperience),
            soloDrivingRange: drivingExperience.soloDrivingRange?.memberSoloDrivingRange,
            soloParkingLevel: drivingExperience.soloParkingLevel?.memberSoloParkingLevel,
            level: .seed,
            practiceTypes: preferences.selectedPracticeSituations.map(\.placePracticeType),
            carType: preferences.vehicleType?.memberCarType,
            drivingGoal: drivingGoal.trimmedOrNil
        )
        let analysis = MemberOnboardingLevelPolicy.analyze(baseSubmission)
        let isNavigator = analysis.level == .navigator

        return MemberOnboardingSubmission(
            drivingPeriod: baseSubmission.drivingPeriod,
            recentFrequency: isNavigator ? nil : baseSubmission.recentFrequency,
            roadExperiences: isNavigator ? [] : baseSubmission.roadExperiences,
            soloDrivingRange: isNavigator ? nil : baseSubmission.soloDrivingRange,
            soloParkingLevel: isNavigator ? nil : baseSubmission.soloParkingLevel,
            level: analysis.level,
            practiceTypes: baseSubmission.practiceTypes,
            carType: baseSubmission.carType,
            drivingGoal: baseSubmission.drivingGoal
        )
    }
}

private extension LicenseDrivingPeriod {
    var memberDrivingPeriod: MemberOnboardingSubmission.DrivingPeriod {
        switch self {
        case .lessThanOneMonth: .underOneMonth
        case .oneToTwoMonths: .monthsOneToTwo
        case .threeToFiveMonths: .monthsThreeToFive
        case .sixToElevenMonths: .monthsSixToEleven
        case .oneToTwoYears: .yearsOneToTwo
        case .threeToNineYears: .yearsThreeToNine
        case .overTenYears: .overTenYears
        }
    }
}

private extension RecentDrivingFrequency {
    var memberRecentFrequency: MemberOnboardingSubmission.RecentFrequency {
        switch self {
        case .almostNever: .rarely
        case .oneToTwoMonthly: .monthlyOneToTwo
        case .onceWeekly: .weeklyOne
        case .twoToThreeWeekly: .weeklyTwoToThree
        case .fourOrMoreWeekly: .weeklyFourPlus
        }
    }
}

private extension RoadDrivingExperience {
    var memberRoadExperience: MemberOnboardingSubmission.RoadExperience {
        switch self {
        case .none: .none
        case .accompaniedPractice: .accompanied
        case .professionalTraining: .professionalTraining
        case .soloPractice: .solo
        }
    }
}

private extension SoloDrivingRange {
    var memberSoloDrivingRange: MemberOnboardingSubmission.SoloDrivingRange {
        switch self {
        case .nearHome: .nearHome
        case .familiarRoad: .familiarRoad
        case .unfamiliarRoad: .unfamiliarRoad
        case .highwayLong: .highwayLong
        }
    }
}

private extension SoloParkingLevel {
    var memberSoloParkingLevel: MemberOnboardingSubmission.SoloParkingLevel {
        switch self {
        case .none: .none
        case .wideOnly: .wideOnly
        case .familiarPlace: .familiarPlace
        case .mostlyPossible: .mostlyPossible
        }
    }
}

private extension PracticeSituation {
    var placePracticeType: PlacePracticeType {
        switch self {
        case .uTurn: .uTurn
        case .turning: .leftRightTurn
        case .parking: .parking
        case .laneChange: .laneChange
        case .intersection: .intersection
        case .roundabout: .roundabout
        case .unprotectedLeftTurn: .unprotectedLeftTurn
        case .highwayEntry: .highwayEntry
        case .cornering: .cornering
        case .narrowRoad: .narrowRoad
        case .multiLane: .multilane
        case .merging: .merging
        case .straight: .straight
        }
    }
}

private extension VehicleType {
    var memberCarType: MemberOnboardingSubmission.CarType {
        switch self {
        case .compact: .light
        case .small: .compact
        case .medium: .midsize
        case .semiLarge: .semiLarge
        case .large: .large
        case .suv: .suv
        }
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
