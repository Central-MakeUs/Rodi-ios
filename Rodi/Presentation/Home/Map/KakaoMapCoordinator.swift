//
//  KakaoMapCoordinator.swift
//  Rodi
//

import Foundation
import NSObject_Rx
import RxCocoa
import RxRelay
import RxSwift

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

#if canImport(KakaoMapsSDK)
extension KakaoMapContainerView {
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
            mapView?.handleHomeMarkerTap(layerID: layerID, poiID: poiID)
        }
    }
}

#endif
