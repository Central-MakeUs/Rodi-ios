//
//  HomeReducer+Presentation.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reducePresentationAction(_ action: HomeAction.PresentationAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .showRouteGuidanceMessage(let message):
            state.presentation.guidanceSnackbarMessage = message
            return .run { send in
                try? await Task.sleep(for: .milliseconds(2000))
                await send(.presentationAction(.dismissGuidanceSnackbar))
            }
            .cancelTask(id: HomeEffectID.guidanceSnackbarDismissal)

        case .setGuidanceSnackbarMessage(let message):
            state.presentation.guidanceSnackbarMessage = message
            guard message != nil else {
                return .cancel(id: HomeEffectID.guidanceSnackbarDismissal)
            }
            return .run { send in
                try? await Task.sleep(for: .milliseconds(2000))
                await send(.presentationAction(.dismissGuidanceSnackbar))
            }
            .cancelTask(id: HomeEffectID.guidanceSnackbarDismissal)

        case .dismissGuidanceSnackbar:
            state.presentation.guidanceSnackbarMessage = nil

        case .showLocationNoticeMessage(let message):
            state.presentation.locationNoticeMessage = message
            return .run { send in
                try? await Task.sleep(for: .milliseconds(1800))
                await send(.presentationAction(.dismissLocationNoticeMessage))
            }
            .cancelTask(id: HomeEffectID.locationNoticeDismissal)

        case .setLocationNoticeMessage(let message):
            state.presentation.locationNoticeMessage = message
            guard message != nil else {
                return .cancel(id: HomeEffectID.locationNoticeDismissal)
            }
            return .run { send in
                try? await Task.sleep(for: .milliseconds(1800))
                await send(.presentationAction(.dismissLocationNoticeMessage))
            }
            .cancelTask(id: HomeEffectID.locationNoticeDismissal)

        case .dismissLocationNoticeMessage:
            state.presentation.locationNoticeMessage = nil

        case .showLocationSettingsAlert:
            state.presentation.showsLocationSettingsAlert = true

        case .setLocationSettingsAlertPresented(let isPresented):
            state.presentation.showsLocationSettingsAlert = isPresented

        case .setLegalSettingsPresented(let isPresented):
            state.presentation.showsLegalSettings = isPresented
        }

        return .none
    }
}
