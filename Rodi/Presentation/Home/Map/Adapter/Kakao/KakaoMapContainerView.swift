//
//  KakaoMapContainerView.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import SwiftUI
import KakaoMapsSDK

enum RodiMapVisibilityState: Equatable {
    case interactive
    case covered

    var isActive: Bool {
        self == .interactive
    }
}

struct KakaoMapContainerView: UIViewRepresentable {
    let cameraTarget: RodiCoordinate
    let cameraRequestID: Int
    let animatedCameraRequestID: Int?
    let cameraFocus: RodiMapCameraFocus
    let userLocation: RodiCoordinate?
    let userHeadingDegrees: Double?
    let routeOverlay: RodiRouteOverlay?
    let mapMarkers: [RodiMapMarker]
    let logoBottomInset: CGFloat
    let cameraBottomInset: CGFloat
    let isInteractionEnabled: Bool
    let visibilityState: RodiMapVisibilityState
    let onEvent: (RodiMapEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeUIView(context: Context) -> UIView {
        #if canImport(KakaoMapsSDK)
        guard KakaoConfiguration.hasNativeAppKey else {
            let view = MissingKakaoMapView()
            view.configure(message: "카카오맵 API 키를 확인해주세요.")
            context.coordinator.reportFailure("카카오맵 API 키를 확인해주세요.")
            return view
        }

        let view = RodiKakaoMapView()
        view.configure(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState,
            coordinator: context.coordinator
        )
        return view
        #else
        let view = MissingKakaoMapView()
        view.configure(message: "KakaoMapsSDK가 연결되지 않았어요.")
        context.coordinator.reportFailure("KakaoMapsSDK가 연결되지 않았어요.")
        return view
        #endif
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        #if canImport(KakaoMapsSDK)
        guard let view = uiView as? RodiKakaoMapView else { return }
        view.update(
            cameraTarget: cameraTarget,
            cameraRequestID: cameraRequestID,
            animatedCameraRequestID: animatedCameraRequestID,
            cameraFocus: cameraFocus,
            userLocation: userLocation,
            userHeadingDegrees: userHeadingDegrees,
            routeOverlay: routeOverlay,
            mapMarkers: mapMarkers,
            logoBottomInset: logoBottomInset,
            cameraBottomInset: cameraBottomInset,
            isInteractionEnabled: isInteractionEnabled,
            visibilityState: visibilityState
        )
        #endif
    }
}
