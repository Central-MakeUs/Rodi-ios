//
//  MemberProfile.swift
//  Rodi
//

import Foundation

struct CourseTutorialCompletion: Equatable {
    /// 서버가 기록한 완료 시각 원문이다. 시간대 표기가 없는 응답도 허용하므로 변환 없이 보존한다.
    let completedAt: String?
}

/// 마이페이지에 표시하는 로그인 회원의 요약 정보입니다.
struct MemberProfile: Equatable {
    let nickname: String
    let level: Level
    let recommendationTags: [String]
    let drivingGoal: String?
    let savedPlaceCount: Int
    let levelProgress: LevelProgress?

    struct LevelProgress: Equatable {
        let totalDistanceKm: Double
        let currentLevelStartKm: Double
        let nextLevelKm: Double?
        let progressPercent: Int

        var progressFraction: Double {
            Double(min(max(progressPercent, 0), 100)) / 100
        }
    }

    enum Level: String, Equatable {
        case seed = "SEED"
        case rookie = "ROOKIE"
        case owner = "OWNER"
        case explorer = "EXPLORER"
        case navigator = "NAVIGATOR"

        var displayName: String {
            switch self {
            case .seed: "Seed"
            case .rookie: "Rookie"
            case .owner: "Owner"
            case .explorer: "Explorer"
            case .navigator: "Navigator"
            }
        }
    }
}
