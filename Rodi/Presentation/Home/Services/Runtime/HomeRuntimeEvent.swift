//
//  HomeRuntimeEvent.swift
//  Rodi
//

import Foundation

enum HomeRuntimeEvent {
    case filterAnchorCoordinateChanged(RodiCoordinate)
    case radiusFilterReset(HomeRadiusFilter)
    case selectionInvalidated
    case renderedMapMarkersChanged([RodiMapMarker])
    case mapErrorMessageChanged(String?)
    case mapLoadingChanged(Bool)
    case shouldRenderMapChanged(Bool)
    case cameraStateChanged(
        target: RodiCoordinate,
        requestID: Int,
        animatedRequestID: Int?,
        focus: RodiMapCameraFocus
    )
    case userLocationCoordinateChanged(RodiCoordinate?)
    case userHeadingDegreesChanged(Double?)
    case locationPermissionChanged(Bool)
    case currentLocationButtonActiveChanged(Bool)
    case locationNoticeRequested(String)
    case locationPermissionAlertRequested
}
