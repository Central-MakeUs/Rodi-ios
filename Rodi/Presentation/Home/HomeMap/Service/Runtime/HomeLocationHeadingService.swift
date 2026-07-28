//
//  HomeLocationHeadingService.swift
//  Rodi
//

import CoreLocation

extension HomeMapRuntimeService {
    func startHeadingUpdatesIfAvailable() {
        guard CLLocationManager.headingAvailable() else {
            RodiLogger.info("Heading updates unavailable on this device.")
            return
        }

        locationManager.startUpdatingHeading()
        RodiLogger.info("Heading updates started.")
    }
}
