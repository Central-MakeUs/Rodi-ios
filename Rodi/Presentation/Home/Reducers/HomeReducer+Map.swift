//
//  HomeReducer+Map.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reduceMapAction(_ action: HomeAction.MapAction, state: inout HomeState) -> Effect<HomeAction> {
        switch action {
        case .ready:
            state.map.errorMessage = nil
            state.map.isReady = true
            state.map.isLoading = false

        case .viewportChanged(_, let zoomLevel, _, _):
            state.map.zoomLevel = zoomLevel

        case .cameraMoveFinished(let requestID):
            guard state.map.animatedCameraRequestID == requestID else { break }
            state.map.animatedCameraRequestID = nil
            state.location.isCurrentLocationButtonActive = false

        case .loadingFailed(let message):
            state.map.errorMessage = message
            state.map.isReady = false
            state.map.isLoading = false

        case .retryLoading:
            guard state.map.isNetworkUnavailable else { break }
            state.map.isRetryingAfterNetworkFailure = true
            state.map.isLoading = true
            return .run { send in
                try? await Task.sleep(for: .milliseconds(1200))
                await send(.mapAction(.finishLoadingRetry))
            }

        case .finishLoadingRetry:
            state.map.isRetryingAfterNetworkFailure = false
            state.map.isLoading = !state.map.isReady

        case .setRetryingAfterNetworkFailure(let isRetrying):
            state.map.isRetryingAfterNetworkFailure = isRetrying

        case .setNetworkUnavailable(let isUnavailable):
            state.map.isNetworkUnavailable = isUnavailable

        case .setErrorMessage(let message):
            state.map.errorMessage = message

        case .setLoading(let isLoading):
            state.map.isLoading = isLoading

        case .setShouldRender(let shouldRender):
            state.map.shouldRender = shouldRender

        case .setCameraState(let target, let requestID, let animatedRequestID, let focus):
            state.map.cameraTarget = target
            state.map.cameraRequestID = requestID
            state.map.animatedCameraRequestID = animatedRequestID
            state.map.cameraFocus = focus

        case .setCameraRequestID(let requestID):
            state.map.cameraRequestID = requestID
        }

        return .none
    }
}
