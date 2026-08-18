//
//  PracticeRouteMatcher.swift
//  Rodi
//

import CoreLocation
import Foundation

struct PracticeRouteMatch: Equatable {
    let distanceToRouteMeters: Double
    let distanceAlongRouteMeters: Double
    let progress: Double
}

enum PracticeRouteMatcher {
    static func cumulativeDistance(for path: [RodiCoordinate]) -> [Double] {
        guard !path.isEmpty else { return [] }

        var cumulative = [Double](repeating: 0, count: path.count)
        for index in 1..<path.count {
            cumulative[index] = cumulative[index - 1] + distance(from: path[index - 1], to: path[index])
        }
        return cumulative
    }

    static func match(
        location: CLLocation,
        path: [RodiCoordinate],
        cumulativeDistanceMeters: [Double]
    ) -> PracticeRouteMatch? {
        guard path.count >= 2,
              path.count == cumulativeDistanceMeters.count,
              let totalDistance = cumulativeDistanceMeters.last,
              totalDistance > 0
        else {
            return nil
        }

        let locationCoordinate = RodiCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        var closestDistance = Double.greatestFiniteMagnitude
        var closestProgressDistance = 0.0

        for index in 0..<(path.count - 1) {
            let projection = project(
                locationCoordinate,
                ontoSegmentFrom: path[index],
                to: path[index + 1]
            )
            guard projection.distanceMeters < closestDistance else { continue }

            closestDistance = projection.distanceMeters
            let segmentLength = cumulativeDistanceMeters[index + 1] - cumulativeDistanceMeters[index]
            closestProgressDistance = cumulativeDistanceMeters[index] + (segmentLength * projection.fraction)
        }

        return PracticeRouteMatch(
            distanceToRouteMeters: closestDistance,
            distanceAlongRouteMeters: closestProgressDistance,
            progress: min(max(closestProgressDistance / totalDistance, 0), 1)
        )
    }

    static func distance(from first: RodiCoordinate, to second: RodiCoordinate) -> Double {
        CLLocation(latitude: first.latitude, longitude: first.longitude)
            .distance(from: CLLocation(latitude: second.latitude, longitude: second.longitude))
    }

    private static func project(
        _ point: RodiCoordinate,
        ontoSegmentFrom start: RodiCoordinate,
        to end: RodiCoordinate
    ) -> (distanceMeters: Double, fraction: Double) {
        let referenceLatitude = ((start.latitude + end.latitude + point.latitude) / 3) * .pi / 180
        let metersPerLatitudeDegree = 111_132.0
        let metersPerLongitudeDegree = 111_320.0 * cos(referenceLatitude)

        let segmentX = (end.longitude - start.longitude) * metersPerLongitudeDegree
        let segmentY = (end.latitude - start.latitude) * metersPerLatitudeDegree
        let pointX = (point.longitude - start.longitude) * metersPerLongitudeDegree
        let pointY = (point.latitude - start.latitude) * metersPerLatitudeDegree
        let segmentLengthSquared = (segmentX * segmentX) + (segmentY * segmentY)

        guard segmentLengthSquared > 0 else {
            return (hypot(pointX, pointY), 0)
        }

        let fraction = min(max(((pointX * segmentX) + (pointY * segmentY)) / segmentLengthSquared, 0), 1)
        let projectionX = segmentX * fraction
        let projectionY = segmentY * fraction
        return (hypot(pointX - projectionX, pointY - projectionY), fraction)
    }
}
