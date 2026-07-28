//
//  HomePresentationReducer.swift
//  Rodi
//

import Foundation

struct HomePresentationReducer: Reducer {
    enum Action {
        case showSnackbar(String)
        case setSnackbarMessage(String?)
        case dismissSnackbar
        case showLocationSettingsAlert
        case setLocationSettingsAlertPresented(Bool)
        case requestAuthentication
    }

    func reduce(
        _ state: inout HomePresentationState,
        with action: Action
    ) -> Effect<Action> {
        switch action {
        case .showSnackbar(let message), .setSnackbarMessage(let message?):
            state.snackbarMessage = message
            return snackbarDismissalEffect()

        case .setSnackbarMessage(nil):
            state.snackbarMessage = nil
            return .cancel(id: HomeEffectID.snackbarDismissal)

        case .dismissSnackbar:
            state.snackbarMessage = nil

        case .showLocationSettingsAlert:
            state.showsLocationSettingsAlert = true

        case .setLocationSettingsAlertPresented(let isPresented):
            state.showsLocationSettingsAlert = isPresented

        case .requestAuthentication:
            state.authenticationRequestID += 1
        }

        return .none
    }

    private func snackbarDismissalEffect() -> Effect<Action> {
        .run { send in
            try? await Task.sleep(for: .seconds(3))
            await send(.dismissSnackbar)
        }
        .cancelTask(id: HomeEffectID.snackbarDismissal)
    }
}
