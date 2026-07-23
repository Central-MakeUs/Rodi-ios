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
        guard lastAppliedHomeMarkers != markers else { return }

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

        let desiredMarkersByPoiID = Dictionary(
            uniqueKeysWithValues: markers.map { (homeMarkerPoiID(for: $0), $0) }
        )
        let desiredCoordinatesByPoiID = Dictionary(
            uniqueKeysWithValues: markers.map {
                (homeMarkerPoiID(for: $0), displayCoordinate(for: $0, in: markers))
            }
        )
        let currentIDs = Set(renderedHomeMarkersByPoiID.keys)
        let desiredIDs = Set(desiredMarkersByPoiID.keys)

        let updatedIDs = currentIDs.intersection(desiredIDs).filter { poiID in
            renderedHomeMarkersByPoiID[poiID] != desiredMarkersByPoiID[poiID]
                || renderedHomeMarkerCoordinatesByPoiID[poiID] != desiredCoordinatesByPoiID[poiID]
        }
        let addedIDs = desiredIDs.subtracting(currentIDs)

        // Add new POIs before removing obsolete ones so zoom tier transitions never show a blank map.
        addedIDs.sorted().forEach { poiID in
            guard let marker = desiredMarkersByPoiID[poiID],
                  let coordinate = desiredCoordinatesByPoiID[poiID]
            else { return }
            addHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
        }

        updatedIDs.sorted().forEach { poiID in
            guard let marker = desiredMarkersByPoiID[poiID],
                  let coordinate = desiredCoordinatesByPoiID[poiID]
            else { return }
            updateHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
        }

        currentIDs.subtracting(desiredIDs).forEach { poiID in
            homeMarkerLayer?.removePoi(poiID: poiID)
            renderedHomeMarkerIDs.remove(poiID)
            homeMarkerIDsByPoiID.removeValue(forKey: poiID)
            renderedHomeMarkersByPoiID.removeValue(forKey: poiID)
            renderedHomeMarkerCoordinatesByPoiID.removeValue(forKey: poiID)
        }

        lastAppliedHomeMarkers = markers
    }

    func addHomeMarker(
        _ marker: RodiMapMarker,
        poiID: String,
        coordinate: RodiCoordinate,
        manager: LabelManager
    ) {
        let styleID = homeMarkerStyleID(for: marker)
        registerHomeMarkerStyleIfNeeded(for: marker, styleID: styleID, with: manager)

        let options = PoiOptions(styleID: styleID, poiID: poiID)
        options.rank = homeMarkerRank(for: marker.kind)
        options.transformType = .decal
        let point = MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude)

        if let poi = homeMarkerLayer?.addPoi(option: options, at: point) {
            poi.clickable = true
            poi.show()
            renderedHomeMarkerIDs.insert(poiID)
            homeMarkerIDsByPoiID[poiID] = marker.id
            renderedHomeMarkersByPoiID[poiID] = marker
            renderedHomeMarkerCoordinatesByPoiID[poiID] = coordinate
        }
    }

    func updateHomeMarker(
        _ marker: RodiMapMarker,
        poiID: String,
        coordinate: RodiCoordinate,
        manager: LabelManager
    ) {
        guard let poi = homeMarkerLayer?.getPoi(poiID: poiID) else {
            addHomeMarker(marker, poiID: poiID, coordinate: coordinate, manager: manager)
            return
        }

        let styleID = homeMarkerStyleID(for: marker)
        registerHomeMarkerStyleIfNeeded(for: marker, styleID: styleID, with: manager)
        poi.changeStyle(styleID: styleID)
        poi.moveAt(MapPoint(longitude: coordinate.longitude, latitude: coordinate.latitude), duration: 0)
        poi.clickable = true
        renderedHomeMarkersByPoiID[poiID] = marker
        renderedHomeMarkerCoordinatesByPoiID[poiID] = coordinate
        homeMarkerIDsByPoiID[poiID] = marker.id
    }

    func homeMarkerRank(for kind: RodiMapMarkerKind) -> Int {
        switch kind {
        case .parking: 1
        case .course: 2
        case .cluster: 3
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
            "\(Constants.homeCourseMarkerStyleID)_\(stableStyleIdentifier(for: "\(marker.id):\(marker.title)"))"
        case .parking:
            marker.isSelected
                ? Constants.homeParkingActiveMarkerStyleID
                : Constants.homeParkingInactiveMarkerStyleID
        case .cluster:
            "rodi_home_cluster_\(stableStyleIdentifier(for: "\(marker.id):\(marker.title)"))"
        }
    }

    /// Kakao POI style ID는 ASCII로 고정해 주소에 포함된 한글/공백과 무관하게 재사용한다.
    func stableStyleIdentifier(for value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    func homeMarkerPoiID(for marker: RodiMapMarker) -> String {
        "rodi_home_\(marker.id.replacingOccurrences(of: "-", with: "_"))"
    }
}
#endif
