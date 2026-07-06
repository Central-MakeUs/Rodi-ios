//
//  HomeView+Bindings.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

extension HomeView {
    var guidanceSnackbarMessageBinding: Binding<String?> {
        Binding(
            get: { homeStore.state.presentation.guidanceSnackbarMessage },
            set: { homeStore.send(.presentationAction(.setGuidanceSnackbarMessage($0))) }
        )
    }

    var locationNoticeMessageBinding: Binding<String?> {
        Binding(
            get: { homeStore.state.presentation.locationNoticeMessage },
            set: { homeStore.send(.presentationAction(.setLocationNoticeMessage($0))) }
        )
    }

    var showsLocationSettingsAlertBinding: Binding<Bool> {
        Binding(
            get: { homeStore.state.presentation.showsLocationSettingsAlert },
            set: { homeStore.send(.presentationAction(.setLocationSettingsAlertPresented($0))) }
        )
    }

    var showsLegalSettingsBinding: Binding<Bool> {
        Binding(
            get: { homeStore.state.presentation.showsLegalSettings },
            set: { homeStore.send(.presentationAction(.setLegalSettingsPresented($0))) }
        )
    }

}
