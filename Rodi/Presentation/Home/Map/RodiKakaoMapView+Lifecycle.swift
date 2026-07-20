//
//  RodiKakaoMapView+Lifecycle.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit
import NSObject_Rx
import RxSwift

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func activateEngineIfNeeded() {
        guard latestVisibilityState.isActive else { return }
        // prepareEngine 이전의 호출은 실제 엔진 활성화가 아니므로 완료 상태로 기록하면 안 된다.
        // 인증 성공 뒤 addViews callback이 오려면 준비가 끝난 시점에 activateEngine이 반드시 한 번 실행되어야 한다.
        guard didPrepareEngine else { return }
        guard !didActivateEngine || didPauseEngine else { return }
        mapController?.activateEngine()
        didActivateEngine = true
        didPauseEngine = false
    }

    func addMapView() {
        RodiLogger.info("Kakao map addViews requested")
        let point = MapPoint(longitude: latestCameraTarget.longitude, latitude: latestCameraTarget.latitude)
        let info = MapviewInfo(
            viewName: Constants.viewName,
            defaultPosition: point,
            defaultLevel: Constants.mapLevel
        )
        let viewSize = CGSize(
            width: max(mapContainer.bounds.width, bounds.width),
            height: max(mapContainer.bounds.height, bounds.height)
        )
        RodiLogger.info("Kakao map addView size=\(viewSize), containerBounds=\(mapContainer.bounds), bounds=\(bounds)")
        mapController?.addView(info, viewSize: viewSize)
    }

    func didAddMapView() {
        RodiLogger.info("Kakao map addView succeeded")
        guard let map = mapController?.getView(Constants.viewName) as? KakaoMap else {
            RodiLogger.error("Kakao map getView failed after addViewSucceeded")
            coordinator?.reportFailure("카카오맵을 불러오지 못했어요.")
            return
        }

        kakaoMap = map
        RodiLogger.info("Kakao map controller state after getView=\(mapStateDescription())")
        activateEngineIfNeeded()
        finalizeAddedMapViewWhenCreated(attempt: 0)
    }

    func finalizeAddedMapViewWhenCreated(attempt: Int) {
        guard let map = kakaoMap else { return }

        let stateDescription = mapStateDescription()
        if stateDescription.contains("State : not created"), attempt < 12 {
            RodiLogger.info("Kakao map waiting for render view creation attempt=\(attempt), state=\(stateDescription)")
            Observable<Int>
                .timer(.milliseconds(150), scheduler: MainScheduler.instance)
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.activateEngineIfNeeded()
                    self?.finalizeAddedMapViewWhenCreated(attempt: attempt + 1)
                })
                .disposed(by: rx.disposeBag)
            return
        }

        guard !didFinalizeMapView else { return }
        didFinalizeMapView = true
        RodiLogger.info("Kakao map finalizing after render state attempt=\(attempt), state=\(stateDescription)")
        map.eventDelegate = coordinator
        registerMapEventHandlers(on: map)
        map.setPoiEnabled(true)
        map.poiClickable = true
        map.hideCompass()
        map.hideScaleBar()
        updateLogoPosition()
        applyGestureState(isUserInteractionEnabled)
        updateHomeMarkers(with: latestMapMarkers)
        updateRouteOverlay()

        guard latestVisibilityState.isActive else {
            pauseEngineIfNeeded(reason: "didAddMapView_covered")
            coordinator?.reportReady()
            return
        }

        activateEngineIfNeeded()
        updateUserLocationMarker(animatedHeading: false)
        moveCamera(
            to: latestCameraTarget,
            requestID: latestCameraRequestID,
            animated: latestAnimatedCameraRequestID == latestCameraRequestID
        )
        RodiLogger.info(
            "Kakao map ready cameraTarget=\(RodiLogger.coordinate(latestCameraTarget)), userLocation=\(latestUserLocation.logDescription), level=\(Constants.mapLevel), cameraRequestID=\(latestCameraRequestID)"
        )
        completeInitialRenderAfterLayout()
    }

    func reportAuthenticationFailure(_ message: String) {
        RodiLogger.error("Kakao map authentication failure: \(message)")
        coordinator?.reportFailure(message)
    }

    func registerMapEventHandlers(on map: KakaoMap) {
        mapEventHandlers.removeAll()
        let cameraStoppedHandler = map.addCameraStoppedEventHandler(target: self) { target in
            { _ in
                target.reportCurrentViewport()
            }
        }
        mapEventHandlers.append(cameraStoppedHandler)
    }

    func reportCurrentViewport() {
        guard let map = kakaoMap else { return }
        let centerPoint = map.getPosition(CGPoint(x: bounds.midX, y: bounds.midY))
        let coordinate = RodiCoordinate(
            latitude: centerPoint.wgsCoord.latitude,
            longitude: centerPoint.wgsCoord.longitude
        )
        viewportChangeGeneration += 1
        coordinator?.reportViewportChange(
            center: coordinate,
            zoomLevel: map.zoomLevel
        )
    }

    func startEngineIfPossible(reason: String) {
        guard didCreateController else {
            RodiLogger.debug("Kakao map engine not ready to start: no controller, reason=\(reason)")
            return
        }

        guard !didPrepareEngine else { return }

        guard latestVisibilityState.isActive else {
            RodiLogger.debug("Kakao map engine start deferred while covered, reason=\(reason)")
            return
        }

        guard window != nil, !bounds.isEmpty else {
            RodiLogger.debug("Kakao map engine waiting for visible bounds, reason=\(reason), window=\(window != nil), bounds=\(bounds)")
            return
        }

        let prepared = mapController?.prepareEngine() ?? false
        didPrepareEngine = prepared
        RodiLogger.info("Kakao map prepareEngine result=\(prepared), reason=\(reason), bounds=\(bounds), state=\(mapStateDescription())")

        if !prepared {
            coordinator?.reportFailure("카카오맵 엔진을 준비하지 못했어요.")
        }
    }

    func pauseEngineIfNeeded(reason: String) {
        guard didPrepareEngine, !didPauseEngine else { return }
        mapController?.pauseEngine()
        didPauseEngine = true
        RodiLogger.info("Kakao map pauseEngine reason=\(reason)")
    }

    func mapStateDescription() -> String {
        mapController?.getStateDescMessage() ?? "nil"
    }
}
#endif
