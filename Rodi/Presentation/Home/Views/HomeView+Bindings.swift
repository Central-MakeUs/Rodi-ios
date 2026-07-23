//
//  HomeView+Bindings.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import SwiftUI

extension HomeView {
    var snackbarMessageBinding: Binding<String?> {
        Binding(
            get: { homeStore.state.presentation.snackbarMessage },
            set: { homeStore.send(.presentationAction(.setSnackbarMessage($0))) }
        )
    }

    var showsLocationSettingsAlertBinding: Binding<Bool> {
        Binding(
            get: { homeStore.state.presentation.showsLocationSettingsAlert },
            set: { homeStore.send(.presentationAction(.setLocationSettingsAlertPresented($0))) }
        )
    }

}
