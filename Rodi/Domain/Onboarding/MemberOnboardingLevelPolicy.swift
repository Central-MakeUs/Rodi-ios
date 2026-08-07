//
//  MemberOnboardingLevelPolicy.swift
//  Rodi
//

import Foundation

enum MemberOnboardingLevelPolicy {
    static func analyze(_ submission: MemberOnboardingSubmission) -> MemberOnboardingAnalysis {
        if submission.drivingPeriod == .yearsThreeToNine || submission.drivingPeriod == .overTenYears {
            return MemberOnboardingAnalysis(level: .navigator, score: nil)
        }

        let score = drivingPeriodScore(for: submission.drivingPeriod)
            + recentFrequencyScore(for: submission.recentFrequency)
            + roadExperienceScore(for: submission.roadExperiences)
            + soloDrivingRangeScore(for: submission.soloDrivingRange, roadExperiences: submission.roadExperiences)
            + soloParkingLevelScore(for: submission.soloParkingLevel, roadExperiences: submission.roadExperiences)

        let level: MemberOnboardingSubmission.DrivingLevel
        switch score {
        case 0...2:
            level = .seed
        case 3...5:
            level = .rookie
        case 6...9:
            level = .owner
        default:
            level = .explorer
        }

        return MemberOnboardingAnalysis(level: level, score: score)
    }
}

private extension MemberOnboardingLevelPolicy {
    static func drivingPeriodScore(for period: MemberOnboardingSubmission.DrivingPeriod) -> Int {
        switch period {
        case .underOneMonth, .monthsOneToTwo, .monthsThreeToFive:
            return 0
        case .monthsSixToEleven, .yearsOneToTwo:
            return 1
        case .yearsThreeToNine, .overTenYears:
            return 0
        }
    }

    static func recentFrequencyScore(for frequency: MemberOnboardingSubmission.RecentFrequency?) -> Int {
        switch frequency {
        case .rarely, .monthlyOneToTwo, .none:
            0
        case .weeklyOne, .weeklyTwoToThree:
            1
        case .weeklyFourPlus:
            2
        }
    }

    static func roadExperienceScore(for experiences: [MemberOnboardingSubmission.RoadExperience]) -> Int {
        experiences.map { experience in
            switch experience {
            case .none:
                0
            case .accompanied:
                1
            case .professionalTraining, .solo:
                2
            }
        }.max() ?? 0
    }

    static func soloDrivingRangeScore(
        for range: MemberOnboardingSubmission.SoloDrivingRange?,
        roadExperiences: [MemberOnboardingSubmission.RoadExperience]
    ) -> Int {
        guard roadExperiences.contains(.solo) else { return 0 }

        switch range {
        case .nearHome:
            return 1
        case .familiarRoad:
            return 2
        case .unfamiliarRoad:
            return 4
        case .highwayLong:
            return 5
        case .none:
            return 0
        }
    }

    static func soloParkingLevelScore(
        for level: MemberOnboardingSubmission.SoloParkingLevel?,
        roadExperiences: [MemberOnboardingSubmission.RoadExperience]
    ) -> Int {
        guard roadExperiences.contains(.solo) else { return 0 }

        switch level {
        case nil, .some(.none):
            return 0
        case .wideOnly:
            return 1
        case .familiarPlace:
            return 2
        case .mostlyPossible:
            return 4
        }
    }
}
