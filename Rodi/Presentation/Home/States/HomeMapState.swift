//
//  HomeMapState.swift
//  Rodi
//

import Foundation

/// 카카오맵 렌더링, 네트워크 예외, 카메라 이동 요청 상태를 관리한다.
struct HomeMapState {
    var isRetryingAfterNetworkFailure = false
    var isNetworkUnavailable = false
    var errorMessage: String?
    var isLoading = true
    var isReady = false
    var shouldRender = false
    var cameraTarget = RodiCoordinate.seoulCityHall
    var zoomLevel = RodiMapViewport.initial.zoomLevel
    var cameraRequestID = 0
    var animatedCameraRequestID: Int?
    var cameraFocus: RodiMapCameraFocus = .normal
}
