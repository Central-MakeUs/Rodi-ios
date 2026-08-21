//
//  RouteGuidanceService.swift
//  Rodi
//

import Foundation
import UIKit

#if canImport(KakaoSDKNavi)
import KakaoSDKNavi
#endif

enum RouteGuidanceApp: String, CaseIterable, Equatable {
    case kakaoMap
    case kakaoNavi

    var displayName: String {
        switch self {
        case .kakaoMap: "카카오맵"
        case .kakaoNavi: "카카오내비"
        }
    }

    var assetName: String {
        switch self {
        case .kakaoMap: "img_kakao_map"
        case .kakaoNavi: "img_kakao_navi"
        }
    }

    fileprivate var availabilityURL: URL {
        switch self {
        case .kakaoMap: URL(string: "kakaomap://")!
        case .kakaoNavi: URL(string: "kakaonavi-sdk://")!
        }
    }

    fileprivate var appStoreURL: URL {
        switch self {
        case .kakaoMap: URL(string: "https://apps.apple.com/kr/app/id304608425")!
        case .kakaoNavi: URL(string: "https://apps.apple.com/kr/app/id417698849")!
        }
    }
}

enum RouteGuidanceLaunchOption: Equatable {
    case open(RouteGuidanceApp)
    case choose
    case install
}

enum RouteGuidanceResult {
    case openedApp(String? = nil)
    case openedInstallPage
    case failed(String)

    var userMessage: String? {
        switch self {
        case .openedApp(let message): message
        case .openedInstallPage: nil
        case .failed(let message): message
        }
    }
}

@MainActor
struct RouteGuidanceService {
    let kakaoMapWaypointLimit = 5
    let kakaoNaviWaypointLimit = 3
    private let preferredAppStore = UserDefaultsStringStore(key: "routeGuidance.preferredApp")

    func launchOption() -> RouteGuidanceLaunchOption {
        let installedApps = RouteGuidanceApp.allCases.filter(isInstalled)

        switch installedApps.count {
        case 0:
            return .install
        case 1:
            return .open(installedApps[0])
        default:
            if let preferredApp, installedApps.contains(preferredApp) {
                return .open(preferredApp)
            } else {
                return .choose
            }
        }
    }

    func savePreferredApp(_ app: RouteGuidanceApp) {
        preferredAppStore.save(app.rawValue)
    }

    func openInstallPage(for app: RouteGuidanceApp) async -> RouteGuidanceResult {
        await openURL(
            app.appStoreURL,
            success: .openedInstallPage,
            failureMessage: "\(app.displayName) 설치 페이지를 열지 못했어요."
        )
    }

    func open(_ app: RouteGuidanceApp, for item: RodiCourseItem, userLocation: RodiCoordinate?) async -> RouteGuidanceResult {
        guard isInstalled(app) else {
            let result: RouteGuidanceResult = .failed("\(app.displayName)이 설치되어 있지 않아요.")
            track(result: result, app: app, item: item)
            return result
        }

        let payload = RouteGuidancePayload(item: item, userLocation: userLocation)
        guard let payload else {
            let result: RouteGuidanceResult = .failed("경로 안내에 필요한 현재 위치와 목적지가 아직 준비되지 않았어요.")
            track(result: result, app: app, item: item)
            return result
        }

        let result: RouteGuidanceResult
        switch app {
        case .kakaoMap: result = await openKakaoMap(payload)
        case .kakaoNavi: result = await openKakaoNavi(payload)
        }
        track(result: result, app: app, item: item)
        return result
    }

    func openURL(_ url: URL, success: RouteGuidanceResult, failureMessage: String) async -> RouteGuidanceResult {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { opened in
                if opened {
                    RodiLogger.info("External route guidance opened urlScheme=\(url.scheme ?? "unknown")")
                    continuation.resume(returning: success)
                } else {
                    RodiLogger.warning("External route guidance failed urlScheme=\(url.scheme ?? "unknown")")
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

    private var preferredApp: RouteGuidanceApp? {
        guard let rawValue = preferredAppStore.load() else { return nil }
        return RouteGuidanceApp(rawValue: rawValue)
    }

    private func isInstalled(_ app: RouteGuidanceApp) -> Bool {
        UIApplication.shared.canOpenURL(app.availabilityURL)
    }

    private func track(result: RouteGuidanceResult, app: RouteGuidanceApp, item: RodiCourseItem) {
        let provider = app == .kakaoMap ? "kakao_map" : "kakao_navi"

        switch result {
        case .openedApp:
            RodiAnalytics.track(.routeGuidanceOpened(
                navigationProvider: provider,
                placeType: item.type.rawValue,
                source: "place_detail"
            ))
        case .openedInstallPage:
            break
        case .failed(let message):
            RodiAnalytics.track(.routeGuidanceLaunchFailed(
                navigationProvider: provider,
                placeType: item.type.rawValue
            ))
            RodiCrashReporter.record(message: message, endpointCategory: "external_navigation")
        }
    }

    private func openKakaoMap(_ payload: RouteGuidancePayload) async -> RouteGuidanceResult {
        let appURL = makeKakaoMapRouteURL(
            base: URLComponents(string: "kakaomap://route"),
            payload: payload,
            waypointLimit: kakaoMapWaypointLimit
        )
        guard let appURL else { return .failed("카카오맵 경로 URL을 만들지 못했어요.") }
        return await openURL(
            appURL,
            success: .openedApp(waypointLimitMessage(app: "카카오맵", actualCount: payload.waypoints.count, limit: kakaoMapWaypointLimit)),
            failureMessage: "카카오맵을 열지 못했어요."
        )
    }

    private func openKakaoNavi(_ payload: RouteGuidancePayload) async -> RouteGuidanceResult {
        #if canImport(KakaoSDKNavi)
        let destination = NaviLocation(name: payload.destination.name, x: payload.destination.coordinate.longitudeString, y: payload.destination.coordinate.latitudeString)
        let viaList = payload.waypoints.prefix(kakaoNaviWaypointLimit).map {
            NaviLocation(name: $0.name, x: $0.coordinate.longitudeString, y: $0.coordinate.latitudeString)
        }
        let option = NaviOption(
            coordType: .WGS84,
            rpOption: .Recommended,
            routeInfo: false,
            startX: payload.start.coordinate.longitudeString,
            startY: payload.start.coordinate.latitudeString
        )
        guard let naviURL = NaviApi.shared.navigateUrl(destination: destination, option: option, viaList: viaList.isEmpty ? nil : Array(viaList)) else {
            return .failed("카카오내비 경로 URL을 만들지 못했어요.")
        }
        return await openURL(
            naviURL,
            success: .openedApp(waypointLimitMessage(app: "카카오내비", actualCount: payload.waypoints.count, limit: kakaoNaviWaypointLimit)),
            failureMessage: "카카오내비를 열지 못했어요."
        )
        #else
        return .failed("카카오내비 SDK가 연결되어 있지 않아요.")
        #endif
    }

    private func makeKakaoMapRouteURL(base: URLComponents?, payload: RouteGuidancePayload, waypointLimit: Int) -> URL? {
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
