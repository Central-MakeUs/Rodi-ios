//
//  HomeRuntimeService+Heading.swift
//  Rodi
//

import CoreLocation

extension HomeRuntimeService {
    func startHeadingUpdatesIfAvailable() {
        guard CLLocationManager.headingAvailable() else {
            RodiLogger.info("Heading updates unavailable on this device.")
            return
        }

        locationManager.startUpdatingHeading()
        RodiLogger.info("Heading updates started.")
    }
}
