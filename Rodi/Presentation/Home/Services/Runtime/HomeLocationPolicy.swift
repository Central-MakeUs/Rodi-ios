//
//  HomeLocationPolicy.swift
//  Rodi
//

import CoreLocation

enum HomeLocationPolicy {
    static func accuracy(for kind: LocationRequestKind) -> CLLocationAccuracy {
        switch kind {
        case .initial:
            kCLLocationAccuracyHundredMeters
        case .userInitiated:
            kCLLocationAccuracyBest
        }
    }

    static func isSupportedServiceCoordinate(_ coordinate: RodiCoordinate) -> Bool {
        (33.0...39.5).contains(coordinate.latitude)
            && (124.0...132.5).contains(coordinate.longitude)
    }
}
