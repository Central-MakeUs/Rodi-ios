//
//  PracticeTrackingModels.swift
//  Rodi
//

import Foundation

enum PracticeTrackingPhase: String, Codable, Equatable {
    case headingToCourse
    case drivingCourse
    case completed
    case cancelled
    case interrupted

    var displayTitle: String {
        switch self {
        case .headingToCourse: "코스까지 이동 중"
        case .drivingCourse: "연습 코스 주행 중"
        case .completed: "연습 코스 완료"
        case .cancelled, .interrupted: "연습 기록 종료"
        }
    }

    var isTerminal: Bool {
        switch self {
        case .completed, .cancelled, .interrupted:
            true
        case .headingToCourse, .drivingCourse:
            false
        }
    }
}

/// 사용자의 원본 GPS 궤적은 저장하지 않는다.
/// routePath는 완주 판단 기준이 되는 코스의 도로 polyline이다.
struct PracticeTrackingSession: Codable, Equatable, Identifiable {
    let id: UUID
    let courseID: Int
    let courseName: String
    let placeType: PracticeMeasurementPlaceType?
    let rabbitAssetName: String?
    let routePath: [RodiCoordinate]
    let cumulativeRouteDistanceMeters: [Double]
    let startedAt: Date
    var phase: PracticeTrackingPhase
    var drivingStartedAt: Date?
    var lastAcceptedLocationAt: Date?
    var courseProgress: Double
    var activeDrivingSeconds: TimeInterval
    var matchedSampleCount: Int
    var initialDistanceToCourseStartMeters: Double?
    var distanceToCourseStartMeters: Double?
    var lastMatchedLocationAt: Date?
    var initialMatchedRouteDistanceMeters: Double?
    var furthestMatchedRouteDistanceMeters: Double?
    var drivenRouteDistanceMeters: Double?

    var completedAt: Date?

    var isReviewEligible: Bool {
        phase == .completed
    }

    var isParking: Bool {
        placeType == .parking
    }

    var totalCourseDistanceMeters: Double {
        cumulativeRouteDistanceMeters.last ?? 0
    }

    var approachProgress: Double {
        guard phase == .headingToCourse,
              let initialDistanceToCourseStartMeters,
              initialDistanceToCourseStartMeters > 0,
              let distanceToCourseStartMeters
        else {
            return phase == .headingToCourse ? 0 : 1
        }

        return min(max(1 - (distanceToCourseStartMeters / initialDistanceToCourseStartMeters), 0), 1)
    }

    var drivenRouteDistance: Double {
        drivenRouteDistanceMeters ?? 0
    }

    var requiredDrivingDistanceMeters: Double {
        min(totalCourseDistanceMeters * 0.4, 5_000)
    }

    var directionalAdvanceMeters: Double {
        guard let initialMatchedRouteDistanceMeters,
              let furthestMatchedRouteDistanceMeters
        else { return 0 }

        return max(furthestMatchedRouteDistanceMeters - initialMatchedRouteDistanceMeters, 0)
    }

    var requiredDirectionalAdvanceMeters: Double {
        0
    }
}

enum PracticeLiveActivityRabbitAsset {
    static let navigation = "img_rabbit_navigation"

    static func name(for level: MemberProfile.Level) -> String {
        switch level {
        case .seed: "img_rabbit_seed"
        case .rookie: "img_rabbit_rookie"
        case .owner: "img_rabbit_owner"
        case .explorer: "img_rabbit_explorer"
        case .navigator: navigation
        }
    }
}

enum PracticeTrackingStartResult: Equatable {
    case started
    case authorizationRequested
    case reducedAccuracyRequested
    case unavailable(String)
}
