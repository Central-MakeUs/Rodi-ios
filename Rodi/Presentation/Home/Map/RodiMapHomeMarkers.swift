//
//  RodiMapHomeMarkers.swift
//  Rodi
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func updateHomeMarkers(with markers: [RodiMapMarker]) {
        guard let map = kakaoMap else { return }

        let manager = map.getLabelManager()
        registerHomeMarkerStylesIfNeeded(with: manager)

        if homeMarkerLayer == nil {
            let options = LabelLayerOptions(
                layerID: Constants.homeMarkerLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 7_000
            )
            homeMarkerLayer = manager.addLabelLayer(option: options)
            homeMarkerLayer?.setClickable(true)
        }

        let desiredIDs = Set(markers.map { homeMarkerPoiID(for: $0) })
        renderedHomeMarkerIDs.subtracting(desiredIDs).forEach {
            homeMarkerLayer?.removePoi(poiID: $0)
            renderedHomeMarkerIDs.remove($0)
            homeMarkerIDsByPoiID.removeValue(forKey: $0)
        }

        markers.forEach { marker in
            let poiID = homeMarkerPoiID(for: marker)
            guard !renderedHomeMarkerIDs.contains(poiID) else { return }

            let styleID = homeMarkerStyleID(for: marker)
            registerHomeMarkerStyleIfNeeded(for: marker, styleID: styleID, with: manager)

            let options = PoiOptions(styleID: styleID, poiID: poiID)
            options.rank = marker.kind == .parking ? 1 : 2
            options.transformType = .decal
            let displayCoordinate = displayCoordinate(for: marker, in: markers)
            let point = MapPoint(
                longitude: displayCoordinate.longitude,
                latitude: displayCoordinate.latitude
            )

            if let poi = homeMarkerLayer?.addPoi(option: options, at: point) {
                poi.clickable = true
                poi.show()
                renderedHomeMarkerIDs.insert(poiID)
                homeMarkerIDsByPoiID[poiID] = marker.id
            }
        }
    }

    func displayCoordinate(for marker: RodiMapMarker, in markers: [RodiMapMarker]) -> RodiCoordinate {
        let duplicateMarkers = markers.filter {
            coordinateKey(for: $0.coordinate) == coordinateKey(for: marker.coordinate)
        }
        guard duplicateMarkers.count > 1,
              let duplicateIndex = duplicateMarkers.firstIndex(where: { $0.id == marker.id })
        else {
            return marker.coordinate
        }

        let middleIndex = Double(duplicateMarkers.count - 1) / 2
        let offsetIndex = Double(duplicateIndex) - middleIndex
        let longitudeOffset = offsetIndex * Constants.duplicateMarkerLongitudeOffset
        return RodiCoordinate(
            latitude: marker.coordinate.latitude,
            longitude: marker.coordinate.longitude + longitudeOffset
        )
    }

    func coordinateKey(for coordinate: RodiCoordinate) -> String {
        "\(String(format: "%.6f", coordinate.latitude)):\(String(format: "%.6f", coordinate.longitude))"
    }

    func handleHomeMarkerTap(layerID: String, poiID: String) {
        guard layerID == Constants.homeMarkerLayerID else { return }
        guard let markerID = homeMarkerIDsByPoiID[poiID] else {
            RodiLogger.warning("Kakao home marker tap ignored: missing marker id poiID=\(poiID)")
            return
        }

        RodiLogger.info("Kakao home marker tapped markerID=\(markerID), poiID=\(poiID)")
        coordinator?.reportMarkerTap(markerID)
    }

    func homeMarkerStyleID(for marker: RodiMapMarker) -> String {
        switch marker.kind {
        case .course:
            "\(Constants.homeCourseMarkerStyleID)_\(marker.id.replacingOccurrences(of: "-", with: "_"))"
        case .parking:
            Constants.homeParkingMarkerStyleID
        }
    }

    func homeMarkerPoiID(for marker: RodiMapMarker) -> String {
        "rodi_home_\(marker.id.replacingOccurrences(of: "-", with: "_"))"
    }
}
#endif
