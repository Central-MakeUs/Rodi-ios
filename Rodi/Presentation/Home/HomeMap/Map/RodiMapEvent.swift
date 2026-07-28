//
//  RodiMapEvent.swift
//  Rodi
//

import Foundation

enum RodiMapEvent {
    case ready
    case markerTap(String)
    case viewportChanged(
        center: RodiCoordinate,
        zoomLevel: Int,
        viewport: PlaceViewport,
        isUserInitiated: Bool
    )
    case cameraMoveFinished(requestID: Int)
    case failed(String)
}
