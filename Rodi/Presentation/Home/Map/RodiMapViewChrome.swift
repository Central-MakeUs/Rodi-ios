//
//  RodiMapViewChrome.swift
//  Rodi
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func updateLogoPosition() {
        guard let map = kakaoMap else { return }
        let inset = max(12, latestLogoBottomInset)
        let origin = GuiAlignment(vAlign: .bottom, hAlign: .left)
        map.setLogoPosition(origin: origin, position: CGPoint(x: 16, y: -inset))
    }

    func applyGestureState(_ isEnabled: Bool) {
        guard let map = kakaoMap else { return }
        map.setGestureEnable(type: .pan, enable: isEnabled)
        map.setGestureEnable(type: .zoom, enable: isEnabled)
        map.setGestureEnable(type: .rotate, enable: isEnabled)
        map.setGestureEnable(type: .tilt, enable: isEnabled)
        map.setGestureEnable(type: .doubleTapZoomIn, enable: isEnabled)
        map.setGestureEnable(type: .twoFingerTapZoomOut, enable: isEnabled)
        map.setGestureEnable(type: .longTapAndDrag, enable: isEnabled)
        map.setGestureEnable(type: .rotateZoom, enable: isEnabled)
        map.setGestureEnable(type: .oneFingerZoom, enable: isEnabled)
    }

}
#endif
