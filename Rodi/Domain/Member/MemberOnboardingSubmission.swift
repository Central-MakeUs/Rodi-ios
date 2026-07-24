//
//  MemberOnboardingSubmission.swift
//  Rodi
//

import Foundation

/// 서버에 제출하는 회원 온보딩 정보입니다.
struct MemberOnboardingSubmission {
    let drivingPeriod: DrivingPeriod
    let recentFrequency: RecentFrequency?
    let roadExperiences: [RoadExperience]
    let soloDrivingRange: SoloDrivingRange?
    let soloParkingLevel: SoloParkingLevel?
    let level: DrivingLevel
    let practiceTypes: [PlacePracticeType]
    let carType: CarType?
    let drivingGoal: String?
}

struct MemberOnboardingAnalysis: Equatable {
    let level: MemberOnboardingSubmission.DrivingLevel
    /// Navigator는 기간 기준 강제 배정이므로 점수를 두지 않습니다.
    let score: Int?
}

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

extension MemberOnboardingSubmission {
    enum DrivingPeriod: String {
        case underOneMonth = "UNDER_1_MONTH"
        case monthsOneToTwo = "MONTHS_1_2"
        case monthsThreeToFive = "MONTHS_3_5"
        case monthsSixToEleven = "MONTHS_6_11"
        case yearsOneToTwo = "YEARS_1_2"
        case yearsThreeToNine = "YEARS_3_9"
        case overTenYears = "OVER_10_YEARS"
    }

    enum RecentFrequency: String {
        case rarely = "RARELY"
        case monthlyOneToTwo = "MONTHLY_1_2"
        case weeklyOne = "WEEKLY_1"
        case weeklyTwoToThree = "WEEKLY_2_3"
        case weeklyFourPlus = "WEEKLY_4_PLUS"
    }

    enum RoadExperience: String {
        case none = "NONE"
        case accompanied = "ACCOMPANIED"
        case professionalTraining = "PROFESSIONAL_TRAINING"
        case solo = "SOLO"
    }

    enum SoloDrivingRange: String {
        case nearHome = "NEAR_HOME"
        case familiarRoad = "FAMILIAR_ROAD"
        case unfamiliarRoad = "UNFAMILIAR_ROAD"
        case highwayLong = "HIGHWAY_LONG"
    }

    enum SoloParkingLevel: String {
        case none = "NONE"
        case wideOnly = "WIDE_ONLY"
        case familiarPlace = "FAMILIAR_PLACE"
        case mostlyPossible = "MOSTLY_POSSIBLE"
    }

    enum DrivingLevel: String {
        case seed = "SEED"
        case rookie = "ROOKIE"
        case owner = "OWNER"
        case explorer = "EXPLORER"
        case navigator = "NAVIGATOR"
    }

    enum CarType: String {
        case light = "LIGHT"
        case compact = "COMPACT"
        case midsize = "MIDSIZE"
        case semiLarge = "SEMI_LARGE"
        case large = "LARGE"
        case suv = "SUV"
    }
}
