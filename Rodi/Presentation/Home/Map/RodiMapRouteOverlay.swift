//
//  RodiMapRouteOverlay.swift
//  Rodi
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func updateRouteOverlay() {
        guard let map = kakaoMap else { return }

        clearRouteOverlay()

        guard let routeOverlay = latestRouteOverlay else { return }

        let labelManager = map.getLabelManager()
        let shapeManager = map.getShapeManager()
        registerRouteStylesIfNeeded(labelManager: labelManager, shapeManager: shapeManager)

        if routeMarkerLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.routeMarkerLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 9_000
            )
            routeMarkerLayer = labelManager.addLabelLayer(option: options)
        }

        if routeShapeLayer == nil {
            routeShapeLayer = shapeManager.addShapeLayer(layerID: Constants.routeShapeLayerID, zOrder: 8_500)
        }

        routeOverlay.points.filter { $0.role != .waypoint }.forEach { point in
            let poiID = "rodi_route_marker_\(routeOverlay.courseID)_\(point.id)"
            let options = PoiOptions(styleID: markerStyleID(for: point.role), poiID: poiID)
            options.rank = 1
            options.transformType = .decal
            let mapPoint = MapPoint(
                longitude: point.coordinate.longitude,
                latitude: point.coordinate.latitude
            )

            if let poi = routeMarkerLayer?.addPoi(option: options, at: mapPoint) {
                poi.show()
                routeMarkerPoiIDs.append(poiID)
            }
        }

        let pathPoints = routeOverlay.path.map {
            MapPoint(longitude: $0.longitude, latitude: $0.latitude)
        }
        if pathPoints.count >= 2 {
            let options = MapPolylineShapeOptions(
                shapeID: Constants.routePolylineShapeID,
                styleID: Constants.routePolylineStyleID,
                zOrder: 0
            )
            options.polylines = [MapPolyline(line: pathPoints, styleIndex: 0)]
            routeShapeLayer?.addMapPolylineShape(options)?.show()
            focusRouteArea(routeOverlay.path)
        }

        RodiLogger.info(
            "Kakao route overlay rendered courseID=\(routeOverlay.courseID), markerCount=\(routeOverlay.points.count), pathCount=\(routeOverlay.path.count), isRoadRoute=\(routeOverlay.isRoadRoute)"
        )
    }

    func clearRouteOverlay() {
        routeMarkerPoiIDs.forEach {
            routeMarkerLayer?.removePoi(poiID: $0)
        }
        routeMarkerPoiIDs.removeAll()
        routeShapeLayer?.removeMapPolylineShape(shapeID: Constants.routePolylineShapeID)
    }

    func focusRouteArea(_ coordinates: [RodiCoordinate]) {
        guard let map = kakaoMap, coordinates.count >= 2 else { return }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        guard
            let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else {
            return
        }

        let latitudeSpan = max(maxLatitude - minLatitude, 0.032)
        let longitudeSpan = max(maxLongitude - minLongitude, 0.032)
        let bottomCoverageRatio = bounds.height > 0
            ? min(max(latestCameraBottomInset / bounds.height, 0), 0.7)
            : 0.4
        let bottomLatitudePadding = 0.85 + bottomCoverageRatio * 2.05
        let topLatitudePadding = 0.55
        let paddedMinLatitude = minLatitude - latitudeSpan * bottomLatitudePadding
        let paddedMaxLatitude = maxLatitude + latitudeSpan * topLatitudePadding
        let paddedMinLongitude = minLongitude - longitudeSpan * 0.65
        let paddedMaxLongitude = maxLongitude + longitudeSpan * 0.65
        let paddedPoints = [
            MapPoint(longitude: paddedMinLongitude, latitude: paddedMinLatitude),
            MapPoint(longitude: paddedMaxLongitude, latitude: paddedMinLatitude),
            MapPoint(longitude: paddedMinLongitude, latitude: paddedMaxLatitude),
            MapPoint(longitude: paddedMaxLongitude, latitude: paddedMaxLatitude)
        ]
        let area = AreaRect(points: paddedPoints)
        let update = CameraUpdate.make(area: area, levelLimit: -1)
        let options = CameraAnimationOptions(
            autoElevation: true,
            consecutive: false,
            durationInMillis: Constants.focusAnimationDurationMillis
        )
        map.animateCamera(cameraUpdate: update, options: options)
        RodiLogger.info(
            "Kakao route camera focused with bottom-sheet padding latSpan=\(latitudeSpan), lngSpan=\(longitudeSpan), bottomRatio=\(bottomCoverageRatio), bottomPadding=\(bottomLatitudePadding), points=\(coordinates.count)"
        )
    }

}
#endif
