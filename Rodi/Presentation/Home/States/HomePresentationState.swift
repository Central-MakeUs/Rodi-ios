//
//  HomePresentationState.swift
//  Rodi
//

import Foundation

/// snackbar, 위치 권한 alert, 약관/설정 sheet 표시 상태를 관리한다.
struct HomePresentationState {
    var guidanceSnackbarMessage: String?
    var locationNoticeMessage: String?
    var showsLocationSettingsAlert = false
}
