//
//  LocationPermissionRequester.swift
//  Rodi
//

import CoreLocation

final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionRequester()

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        guard manager.authorizationStatus == .notDetermined else { return }
        RodiAnalytics.track(.locationPermissionPrompted)
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: String
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            status = "authorized"
        case .denied:
            status = "denied"
        case .restricted:
            status = "restricted"
        case .notDetermined:
            return
        @unknown default:
            status = "unknown"
        }
        RodiAnalytics.track(.locationPermissionResult(status: status))
    }
}
