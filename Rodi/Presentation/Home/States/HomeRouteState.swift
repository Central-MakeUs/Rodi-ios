//
//  HomeRouteState.swift
//  Rodi
//

import Foundation

/// 선택된 코스의 경로 overlay와 경로 API 로딩/오류 메시지를 관리한다.
struct HomeRouteState {
    var selectedRouteOverlay: RodiRouteOverlay?
    var isRouteLoading = false
    var routeStatusMessage: String?
}
