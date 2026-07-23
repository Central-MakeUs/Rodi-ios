//
//  RodiMapModels.swift
//  Rodi
//

import Foundation

struct RodiRouteOverlay: Equatable {
    let courseID: Int
    let points: [RodiRouteOverlayPoint]
    let path: [RodiCoordinate]
    let isRoadRoute: Bool
}

struct RodiRouteOverlayPoint: Equatable, Identifiable {
    let id: Int
    let sequence: Int
    let role: RodiCoursePointRole
    let name: String
    let coordinate: RodiCoordinate
}

struct RodiMapMarker: Equatable, Identifiable {
    let id: String
    let kind: RodiMapMarkerKind
    let title: String
    let coordinate: RodiCoordinate
    let isSelected: Bool

    init(
        id: String,
        kind: RodiMapMarkerKind,
        title: String,
        coordinate: RodiCoordinate,
        isSelected: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.coordinate = coordinate
        self.isSelected = isSelected
    }
}

enum RodiMapMarkerKind: Equatable {
    case course
    case parking
    case cluster
}

enum RodiMapCameraFocus: Equatable {
    case normal
    case currentLocation
    case koreaOverview
    case closeSingleLocation
    case cluster([RodiCoordinate])
}
