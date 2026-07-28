//
//  HomeLocationService.swift
//  Rodi
//

import CoreLocation

@MainActor
final class HomeLocationService: NSObject {
    let manager = CLLocationManager()

    var onAuthorizationChanged: ((CLAuthorizationStatus) -> Void)?
    var onLocationsUpdated: (([CLLocation]) -> Void)?
    var onFailure: ((Error) -> Void)?
    var onHeadingUpdated: ((CLHeading) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = HomeLocationPolicy.accuracy(for: .initial)
        manager.headingFilter = 5
    }

    func activate() {
        manager.delegate = self
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
        manager.delegate = nil
    }
}

extension HomeLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.onAuthorizationChanged?(status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            self?.onLocationsUpdated?(locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.onFailure?(error)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            self?.onHeadingUpdated?(newHeading)
        }
    }
}
