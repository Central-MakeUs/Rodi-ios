//
//  RouteGuidancePayload.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation

struct RouteGuidancePayload {
    let start: RouteGuidancePoint
    let waypoints: [RouteGuidancePoint]
    let destination: RouteGuidancePoint

    init?(item: RodiCourseItem, userLocation: RodiCoordinate?) {
        guard let userLocation else { return nil }

        if item.type == .parking {
            start = RouteGuidancePoint(name: "현재 위치", coordinate: userLocation)
            waypoints = []
            destination = RouteGuidancePoint(name: item.name, coordinate: item.coordinate)
            return
        }

        let points = item.routeOverlayPoints.sorted { $0.sequence < $1.sequence }
        guard points.count >= 2 else { return nil }

        let startPoint = points.first(where: { $0.role == .start }) ?? points[0]
        let destinationPoint = points.last(where: { $0.role == .end }) ?? points[points.count - 1]

        start = RouteGuidancePoint(name: "현재 위치", coordinate: userLocation)
        destination = RouteGuidancePoint(name: destinationPoint.name, coordinate: destinationPoint.coordinate)

        let courseStart = RouteGuidancePoint(name: startPoint.name, coordinate: startPoint.coordinate)
        let courseWaypoints = points
            .filter { $0.id != startPoint.id && $0.id != destinationPoint.id }
            .map { RouteGuidancePoint(name: $0.name, coordinate: $0.coordinate) }
        waypoints = [courseStart] + courseWaypoints
    }
}

struct RouteGuidancePoint {
    let name: String
    let coordinate: RodiCoordinate
}

extension RodiCoordinate {
    var kakaoMapRouteValue: String {
        "\(latitudeString),\(longitudeString)"
    }

    var latitudeString: String {
        String(format: "%.7f", latitude)
    }

    var longitudeString: String {
        String(format: "%.7f", longitude)
    }
}
