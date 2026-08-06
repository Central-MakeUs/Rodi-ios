import CoreLocation
import Foundation

@MainActor
final class MapLocationService: NSObject {
    enum Result {
        case resolved(RodiCoordinate)
        case unavailable
        case permissionDenied
    }

    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<Result, Never>?
    private var headingContinuation: AsyncStream<Double>.Continuation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.headingFilter = 5
    }

    func requestLocation() async -> Result {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            requestLocation(for: locationManager.authorizationStatus)
        }
    }

    func headingUpdates() -> AsyncStream<Double> {
        return AsyncStream { continuation in
            headingContinuation?.finish()
            headingContinuation = continuation

            guard CLLocationManager.headingAvailable() else {
                continuation.finish()
                return
            }

            locationManager.startUpdatingHeading()
        }
    }

    private func requestLocation(for status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.permissionDenied)
        @unknown default:
            finish(.unavailable)
        }
    }

    private func finish(_ result: Result) {
        guard let continuation else { return }
        self.continuation = nil
        locationManager.stopUpdatingLocation()
        continuation.resume(returning: result)
    }

    private func isSupported(_ coordinate: RodiCoordinate) -> Bool {
        (33.0...39.5).contains(coordinate.latitude) &&
            (124.0...132.5).contains(coordinate.longitude)
    }
}

extension MapLocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            self?.requestLocation(for: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = RodiCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        Task { @MainActor [weak self] in
            guard let self else { return }
            finish(isSupported(coordinate) ? .resolved(coordinate) : .unavailable)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.finish(.unavailable)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let degrees = newHeading.trueHeading >= 0
            ? newHeading.trueHeading
            : newHeading.magneticHeading
        guard degrees >= 0 else { return }

        Task { @MainActor [weak self] in
            self?.headingContinuation?.yield(degrees)
        }
    }
}
