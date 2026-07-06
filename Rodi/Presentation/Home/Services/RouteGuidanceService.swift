//
//  RouteGuidanceService.swift
//  Rodi
//
//  Created by Codex on 6/28/26.
//

import Foundation
import UIKit

enum RouteGuidanceApp {
    case kakaoMap
    case kakaoNavi
}

enum RouteGuidanceResult {
    case openedApp(String? = nil)
    case openedInstallPage
    case failed(String)

    var userMessage: String? {
        switch self {
        case .openedApp(let message):
            message
        case .openedInstallPage:
            "앱이 설치되어 있지 않아 설치 페이지로 이동했어요."
        case .failed(let message):
            message
        }
    }
}

@MainActor
struct RouteGuidanceService {
    static let shared = RouteGuidanceService()

    let kakaoMapWaypointLimit = 5
    let kakaoNaviWaypointLimit = 3
    let kakaoNaviAppStoreURL = URL(string: "https://apps.apple.com/kr/app/id417698849")

    func open(_ app: RouteGuidanceApp, for item: RodiCourseItem, userLocation: RodiCoordinate?) async -> RouteGuidanceResult {
        let payload = RouteGuidancePayload(item: item, userLocation: userLocation)
        guard let payload else {
            return .failed("경로 안내에 필요한 현재 위치와 목적지가 아직 준비되지 않았어요.")
        }

        switch app {
        case .kakaoMap:
            return await openKakaoMap(payload)
        case .kakaoNavi:
            return await openKakaoNavi(payload)
        }
    }

    func openURL(_ url: URL, success: RouteGuidanceResult, failureMessage: String) async -> RouteGuidanceResult {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { opened in
                if opened {
                    RodiLogger.info("External route guidance opened urlScheme=\(url.scheme ?? "unknown")")
                    continuation.resume(returning: success)
                } else {
                    RodiLogger.warning("External route guidance failed url=\(url.absoluteString)")
                    continuation.resume(returning: .failed(failureMessage))
                }
            }
        }
    }

    func waypointLimitMessage(app: String, actualCount: Int, limit: Int) -> String? {
        guard actualCount > limit else { return nil }
        RodiLogger.warning("Route guidance waypoint truncated app=\(app), actual=\(actualCount), sent=\(limit)")
        return "\(app) 경유지 제한으로 앞 \(limit)개 경유지만 전달했어요."
    }
}
