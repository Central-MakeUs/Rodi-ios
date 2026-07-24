//
//  DrivingExperienceOption.swift
//  Rodi
//

import Foundation

enum LicenseDrivingPeriod: String, CaseIterable, Identifiable {
    case lessThanOneMonth = "1개월 미만"
    case oneToTwoMonths = "1~2개월"
    case threeToFiveMonths = "3~5개월"
    case sixToElevenMonths = "6~11개월"
    case oneToTwoYears = "1~2년"
    case threeToNineYears = "3~9년"
    case overTenYears = "10년 이상"

    var id: String { rawValue }
}

enum RecentDrivingFrequency: String, CaseIterable, Identifiable {
    case almostNever = "거의 없음"
    case oneToTwoMonthly = "월 1~2회"
    case onceWeekly = "주 1회"
    case twoToThreeWeekly = "주 2~3회"
    case fourOrMoreWeekly = "주 4회 이상"

    var id: String { rawValue }
}

enum RoadDrivingExperience: String, CaseIterable, Identifiable {
    case none = "없음"
    case accompaniedPractice = "동승 연습"
    case professionalTraining = "전문 도로 연수"
    case soloPractice = "혼자 연습"

    var id: String { rawValue }
}

enum SoloDrivingRange: String, CaseIterable, Identifiable {
    case nearHome = "집 근처"
    case familiarRoad = "익숙한 길"
    case unfamiliarRoad = "낯선 도로"
    case highwayLong = "고속·장거리"

    var id: String { rawValue }
}

enum SoloParkingLevel: String, CaseIterable, Identifiable {
    case none = "없음"
    case wideOnly = "넓은 곳만"
    case familiarPlace = "익숙한 곳에서만"
    case mostlyPossible = "대부분 가능"

    var id: String { rawValue }
}

enum PracticeSituation: String, CaseIterable, Identifiable {
    case uTurn = "유턴"
    case turning = "좌우 회전"
    case parking = "주차"
    case laneChange = "차선변경"
    case intersection = "교차로"
    case roundabout = "회전 교차로"
    case unprotectedLeftTurn = "비보호 좌회전"
    case highwayEntry = "고속진입"
    case cornering = "코너링"
    case narrowRoad = "좁은 도로 주행"
    case multiLane = "다차로 주행"
    case merging = "합류"
    case straight = "직선주행"

    var id: String { rawValue }
}

enum VehicleType: String, CaseIterable, Identifiable {
    case compact = "경차"
    case small = "소형차"
    case medium = "중형차"
    case semiLarge = "준대형"
    case large = "대형차"
    case suv = "SUV"

    var id: String { rawValue }
}
