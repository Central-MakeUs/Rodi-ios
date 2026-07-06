//
//  RouteGuidanceService+KakaoNavi.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation
import UIKit

#if canImport(KakaoSDKNavi)
import KakaoSDKNavi
#endif

extension RouteGuidanceService {
    func openKakaoNavi(_ payload: RouteGuidancePayload) async -> RouteGuidanceResult {
        #if canImport(KakaoSDKNavi)
        let destination = NaviLocation(
            name: payload.destination.name,
            x: payload.destination.coordinate.longitudeString,
            y: payload.destination.coordinate.latitudeString
        )
        let viaList = payload.waypoints.prefix(kakaoNaviWaypointLimit).map {
            NaviLocation(
                name: $0.name,
                x: $0.coordinate.longitudeString,
                y: $0.coordinate.latitudeString
            )
        }
        let option = NaviOption(
            coordType: .WGS84,
            rpOption: .Recommended,
            routeInfo: false,
            startX: payload.start.coordinate.longitudeString,
            startY: payload.start.coordinate.latitudeString
        )

        guard let naviURL = NaviApi.shared.navigateUrl(
            destination: destination,
            option: option,
            viaList: viaList.isEmpty ? nil : Array(viaList)
        ) else {
            return .failed("카카오내비 경로 URL을 만들지 못했어요.")
        }

        if UIApplication.shared.canOpenURL(naviURL) {
            return await openURL(
                naviURL,
                success: .openedApp(waypointLimitMessage(app: "카카오내비", actualCount: payload.waypoints.count, limit: kakaoNaviWaypointLimit)),
                failureMessage: "카카오내비를 열지 못했어요."
            )
        }

        guard let installURL = kakaoNaviAppStoreURL else {
            return .failed("카카오내비 설치 페이지를 열지 못했어요.")
        }

        return await openURL(installURL, success: .openedInstallPage, failureMessage: "카카오내비 설치 페이지를 열지 못했어요.")
        #else
        return .failed("카카오내비 SDK가 연결되어 있지 않아요.")
        #endif
    }
}
