//
//  HomePresentationState.swift
//  Rodi
//

import Foundation

/// 스낵바와 위치 권한 alert, 약관/설정 sheet 표시 상태를 관리한다.
struct HomePresentationState {
    var snackbarMessage: String?
    var showsLocationSettingsAlert = false
    var authenticationRequestID = 0
}
