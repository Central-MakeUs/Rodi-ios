//
//  HomeLocationState.swift
//  Rodi
//

import Foundation

/// 위치 권한, 사용자 좌표, heading, 내 위치 버튼 활성 상태를 관리한다.
struct HomeLocationState {
    var userLocationCoordinate: RodiCoordinate?
    var userHeadingDegrees: Double?
    var hasLocationPermission = false
    var isCurrentLocationButtonActive = false
}
