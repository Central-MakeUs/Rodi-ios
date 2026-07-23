//
//  HomeReducer+Presentation.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reducePresentationAction(_ action: HomeAction.PresentationAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .showSnackbar(let message):
            state.presentation.snackbarMessage = message
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.presentationAction(.dismissSnackbar))
            }
            .cancelTask(id: HomeEffectID.snackbarDismissal)

        case .setSnackbarMessage(let message):
            state.presentation.snackbarMessage = message
            guard message != nil else {
                return .cancel(id: HomeEffectID.snackbarDismissal)
            }
            return .run { send in
                try? await Task.sleep(for: .seconds(3))
                await send(.presentationAction(.dismissSnackbar))
            }
            .cancelTask(id: HomeEffectID.snackbarDismissal)

        case .dismissSnackbar:
            state.presentation.snackbarMessage = nil

        case .showLocationSettingsAlert:
            state.presentation.showsLocationSettingsAlert = true

        case .setLocationSettingsAlertPresented(let isPresented):
            state.presentation.showsLocationSettingsAlert = isPresented

        case .requestAuthentication:
            state.presentation.authenticationRequestID += 1

        }

        return .none
    }
}
