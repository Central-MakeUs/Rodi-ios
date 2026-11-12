//
//  KakaoMapContainerView.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import SwiftUI
import NSObject_Rx
import RxCocoa
import RxSwift
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

    final class Coordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
        private let onEvent: (RodiMapEvent) -> Void
        private let eventRelay = PublishRelay<RodiMapEvent>()
        private weak var mapView: RodiKakaoMapView?
        private var didReportReady = false

        init(onEvent: @escaping (RodiMapEvent) -> Void) {
            self.onEvent = onEvent
            super.init()
            bindEvents()
        }

        private func bindEvents() {
            eventRelay
                .observe(on: MainScheduler.instance)
                .bind { [weak self] event in
                    self?.handle(event)
                }
                .disposed(by: rx.disposeBag)
        }

        private func handle(_ event: RodiMapEvent) {
            onEvent(event)
        }

        func attach(mapView: RodiKakaoMapView) {
            self.mapView = mapView
        }

        func addViews() {
            RodiLogger.info("Kakao map delegate addViews")
            mapView?.addMapView()
        }

        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            RodiLogger.info("Kakao map delegate addViewSucceeded viewName=\(viewName), viewInfoName=\(viewInfoName)")
            mapView?.didAddMapView()
        }

        func addViewFailed(_ viewName: String, viewInfoName: String) {
            RodiLogger.error("Kakao map delegate addViewFailed viewName=\(viewName), viewInfoName=\(viewInfoName)")
            reportFailure("카카오맵을 불러오지 못했어요.")
        }

        func authenticationSucceeded() {
            RodiLogger.info("Kakao map authenticationSucceeded")
            mapView?.activateEngineIfNeeded()
        }

        func authenticationFailed(_ errorCode: Int, desc: String) {
            RodiLogger.error("Kakao map authenticationFailed code=\(errorCode), desc=\(desc)")
            reportFailure("카카오맵 인증에 실패했어요.")
        }

        func reportReady() {
            guard !didReportReady else { return }
            didReportReady = true
            eventRelay.accept(.ready)
        }

        func reportCameraMoveFinished(_ requestID: Int) {
            eventRelay.accept(.cameraMoveFinished(requestID: requestID))
        }

        func reportMarkerTap(_ markerID: String) {
            eventRelay.accept(.markerTap(markerID))
        }

        func reportRoutePointTap(_ pointID: Int) {
            eventRelay.accept(.routePointTap(pointID))
        }

        func reportViewportChange(
            center: RodiCoordinate,
            zoomLevel: Int,
            viewport: PlaceViewport,
            isUserInitiated: Bool
        ) {
            eventRelay.accept(.viewportChanged(
                center: center,
                zoomLevel: zoomLevel,
                viewport: viewport,
                isUserInitiated: isUserInitiated
            ))
        }

        func reportFailure(_ message: String) {
            eventRelay.accept(.failed(message))
        }

        func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
            mapView?.handlePoiTap(layerID: layerID, poiID: poiID)
        }
    }
}
