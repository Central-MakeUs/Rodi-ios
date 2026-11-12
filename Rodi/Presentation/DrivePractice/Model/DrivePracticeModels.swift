//
//  DrivePracticeModels.swift
//  Rodi
//

import Foundation

enum DrivePracticePhase: String, Codable, Equatable {
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
struct DrivePracticeSession: Codable, Equatable, Identifiable {
    let id: UUID
    let courseID: Int
    let courseName: String
    let placeType: PracticeMeasurementPlaceType?
    let rabbitAssetName: String?
    let routePath: [RodiCoordinate]
    let cumulativeRouteDistanceMeters: [Double]
    let startedAt: Date
    var phase: DrivePracticePhase
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
    
    var analyticsPlaceType: String {
        placeType?.rawValue ?? "unknown"
    }
}


// 토끼 에셋
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

// 시작 결과
enum DrivePracticeStartResult: Equatable {
    case started
    case authorizationRequested
    case reducedAccuracyRequested
    case unavailable(String)
}

// active 상태가 됐을 때 진행 중인 측정 세션 어떻게 다룰 것인가
enum DrivePracticeRestorationDecision: Equatable {
    case continueApproach
    case discardApproach
    case interruptDriving

    static func make(
        session: DrivePracticeSession,
        measurement: PracticeMeasurement?,
        now: Date,
        approachGracePeriod: TimeInterval
    ) -> Self {
        guard let measurement,
              measurement.id == session.id,
              measurement.isActiveTracking
        else {
            return session.phase == .drivingCourse ? .interruptDriving : .discardApproach
        }

        switch session.phase {
        case .headingToCourse:
            return now.timeIntervalSince(measurement.externalHandoffAt) <= approachGracePeriod
                ? .continueApproach
                : .discardApproach
            
        case .drivingCourse:
            return .interruptDriving
            
        case .completed, .cancelled, .interrupted:
            return .discardApproach
        }
    }
}
