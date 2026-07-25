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
    /// 앱 복귀 직후 Metal surface가 비어 있는 경우를 대비해 현재 상태를 한 번만 다시 적용한다.
    /// SwiftUI 입력값은 바뀌지 않으므로 updateUIView만으로는 이 복구가 실행되지 않는다.
    func restoreRenderingAfterApplicationActivation() {
        guard didFinalizeMapView,
              isApplicationActive,
              latestVisibilityState.isActive
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self,
                  isApplicationActive,
                  latestVisibilityState.isActive,
                  let map = kakaoMap
            else { return }

            setNeedsLayout()
            layoutIfNeeded()
            mapContainer.setNeedsLayout()
            mapContainer.layoutIfNeeded()
            activateEngineIfNeeded()
            updateLogoPosition()
            updateHomeMarkers(with: latestMapMarkers)
            updateRouteOverlay()
            moveCamera(
                to: latestCameraTarget,
                requestID: latestCameraRequestID,
                animated: false
            )
            RodiLogger.info(
                "Kakao map rendering restored after application activation level=\(map.zoomLevel), markerCount=\(latestMapMarkers.count)"
            )
        }
    }

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
        guard latestUserLocation == nil,
              latestVisibilityState.isActive,
              isApplicationActive
        else { return }

        let scheduledViewportGeneration = viewportChangeGeneration
        Observable<Int>
            .timer(.milliseconds(450), scheduler: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                guard let self,
                      latestUserLocation == nil,
                      latestVisibilityState.isActive,
                      isApplicationActive
                else { return }
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
