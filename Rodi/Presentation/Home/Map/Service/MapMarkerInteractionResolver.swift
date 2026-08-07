//
//  MapMarkerInteractionResolver.swift
//  Rodi
//

import Foundation

struct MapMarkerInteractionResolver {
    enum Result {
        case cluster(
            marker: RodiMapMarker,
            target: RodiHomeMarkerClusterIndex.ClusterFocusTarget
        )
        case course(marker: RodiMapMarker, courseID: Int)
        case parking(marker: RodiMapMarker, parkingID: Int)
    }

    func resolve(
        markerID: String,
        markers: [RodiMapMarker],
        items: [RodiCourseItem]
    ) -> Result? {
        guard let marker = markers.first(where: { $0.id == markerID }) else {
            return nil
        }

        switch marker.kind {
        case .cluster:
            guard let target = RodiHomeMarkerClusterIndex.focusTarget(
                for: markerID,
                items: items
            ) else {
                return nil
            }
            return .cluster(marker: marker, target: target)

        case .course:
            guard let courseID = items.first(where: {
                $0.type == .course && $0.mapMarker?.id == markerID
            })?.id else {
                return nil
            }
            return .course(marker: marker, courseID: courseID)

        case .parking:
            guard let parkingID = items.first(where: {
                $0.type == .parking && $0.mapMarker?.id == markerID
            })?.id else {
                return nil
            }
            return .parking(marker: marker, parkingID: parkingID)
        }
    }
}
