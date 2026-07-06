//
//  RouteGuidanceService+KakaoMap.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation
import UIKit

extension RouteGuidanceService {
    func openKakaoMap(_ payload: RouteGuidancePayload) async -> RouteGuidanceResult {
        let appURL = makeKakaoMapRouteURL(
            base: URLComponents(string: "kakaomap://route"),
            payload: payload,
            waypointLimit: kakaoMapWaypointLimit
        )

        guard let appURL else {
            return .failed("카카오맵 경로 URL을 만들지 못했어요.")
        }

        if UIApplication.shared.canOpenURL(appURL) {
            return await openURL(
                appURL,
                success: .openedApp(waypointLimitMessage(app: "카카오맵", actualCount: payload.waypoints.count, limit: kakaoMapWaypointLimit)),
                failureMessage: "카카오맵을 열지 못했어요."
            )
        }

        guard let installURL = URL(string: "https://apps.apple.com/kr/app/id304608425") else {
            return .failed("카카오맵 설치 페이지를 열지 못했어요.")
        }

        return await openURL(installURL, success: .openedInstallPage, failureMessage: "카카오맵 설치 페이지를 열지 못했어요.")
    }

    private func makeKakaoMapRouteURL(
        base: URLComponents?,
        payload: RouteGuidancePayload,
        waypointLimit: Int
    ) -> URL? {
        var components = base
        var queryItems = [
            URLQueryItem(name: "sp", value: payload.start.coordinate.kakaoMapRouteValue),
            URLQueryItem(name: "ep", value: payload.destination.coordinate.kakaoMapRouteValue),
            URLQueryItem(name: "by", value: "car")
        ]

        for (index, waypoint) in payload.waypoints.prefix(waypointLimit).enumerated() {
            queryItems.insert(
                URLQueryItem(name: index == 0 ? "vp" : "vp\(index + 1)", value: waypoint.coordinate.kakaoMapRouteValue),
                at: 1 + index
            )
        }

        components?.queryItems = queryItems
        return components?.url
    }
}
