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
