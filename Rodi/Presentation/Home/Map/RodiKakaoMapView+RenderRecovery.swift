//
//  RodiKakaoMapView+RenderRecovery.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation
import NSObject_Rx
import RxSwift

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func completeInitialRenderAfterLayout() {
        setNeedsLayout()
        layoutIfNeeded()

        let scheduledViewportGeneration = viewportChangeGeneration
        Observable<Int>
            .timer(.milliseconds(200), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                activateEngineIfNeeded()
                updateLogoPosition()
                updateUserLocationMarker(animatedHeading: false)
                updateHomeMarkers(with: latestMapMarkers)
                updateRouteOverlay()
                if scheduledViewportGeneration == viewportChangeGeneration {
                    moveCamera(
                        to: latestCameraTarget,
                        requestID: latestCameraRequestID,
                        animated: false
                    )
                    RodiLogger.info("Kakao map first render recovery applied requestID=\(latestCameraRequestID)")
                } else {
                    RodiLogger.info(
                        "Kakao map first render camera recovery skipped because viewport changed scheduledGeneration=\(scheduledViewportGeneration), currentGeneration=\(viewportChangeGeneration), requestID=\(latestCameraRequestID)"
                    )
                }
                coordinator?.reportReady()
                recoverFallbackTileRenderingIfNeeded()
            })
            .disposed(by: rx.disposeBag)
    }

    func recoverFallbackTileRenderingIfNeeded() {
        guard latestUserLocation == nil, latestVisibilityState.isActive else { return }

        let scheduledViewportGeneration = viewportChangeGeneration
        Observable<Int>
            .timer(.milliseconds(450), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self, latestUserLocation == nil, latestVisibilityState.isActive else { return }
                guard scheduledViewportGeneration == viewportChangeGeneration else {
                    RodiLogger.info(
                        "Kakao fallback tile render recovery skipped because viewport changed scheduledGeneration=\(scheduledViewportGeneration), currentGeneration=\(viewportChangeGeneration), requestID=\(latestCameraRequestID)"
                    )
                    return
                }
                mapContainer.setNeedsLayout()
                mapContainer.layoutIfNeeded()
                mapController?.pauseEngine()
                didPauseEngine = true
                activateEngineIfNeeded()
                updateLogoPosition()
                updateHomeMarkers(with: latestMapMarkers)
                moveCamera(
                    to: latestCameraTarget,
                    requestID: latestCameraRequestID,
                    animated: false
                )
                RodiLogger.info(
                    "Kakao fallback tile render recovery applied requestID=\(latestCameraRequestID), target=\(RodiLogger.coordinate(latestCameraTarget)), markerCount=\(latestMapMarkers.count), state=\(mapStateDescription())"
                )
            })
            .disposed(by: rx.disposeBag)
    }
}
#endif
