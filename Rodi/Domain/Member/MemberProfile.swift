//
//  MemberProfile.swift
//  Rodi
//

import Foundation

/// 마이페이지에 표시하는 로그인 회원의 요약 정보입니다.
struct MemberProfile: Equatable {
    let nickname: String
    let level: Level
    let recommendationTags: [String]
    let drivingGoal: String?
    let savedPlaceCount: Int

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
