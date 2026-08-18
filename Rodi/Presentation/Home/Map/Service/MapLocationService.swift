import CoreLocation
import Foundation

@MainActor
final class MapLocationService: NSObject {
    enum Result {
        case resolved(RodiCoordinate)
        case unavailable
        case permissionDenied(LocationAuthorizationState)
    }

    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<Result, Never>?
    private var headingContinuation: AsyncStream<Double>.Continuation?
    private var locationRequestTimeoutTask: Task<Void, Never>?
    private var locationRequestStartedAt: Date?

    private let locationRequestTimeoutNanoseconds: UInt64 = 20_000_000_000
    private let maximumLocationAge: TimeInterval = 5
    private let maximumHorizontalAccuracy: CLLocationAccuracy = 100

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.headingFilter = 5
    }

    var authorizationState: LocationAuthorizationState {
        authorizationState(for: locationManager.authorizationStatus)
    }

    func requestLocation() async -> Result {
        guard continuation == nil else { return .unavailable }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            locationRequestStartedAt = Date()
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
            scheduleLocationRequestTimeout()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            finish(.permissionDenied(.denied))
        case .restricted:
            finish(.permissionDenied(.restricted))
        @unknown default:
            finish(.unavailable)
        }
    }

    private func authorizationState(
        for status: CLAuthorizationStatus
    ) -> LocationAuthorizationState {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    private func finish(_ result: Result) {
        guard let continuation else { return }
        self.continuation = nil
        locationRequestTimeoutTask?.cancel()
        locationRequestTimeoutTask = nil
        locationRequestStartedAt = nil
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        continuation.resume(returning: result)
    }

    private func scheduleLocationRequestTimeout() {
        locationRequestTimeoutTask?.cancel()
        let timeoutNanoseconds = locationRequestTimeoutNanoseconds
        locationRequestTimeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.finish(.unavailable)
        }
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
            guard let self, continuation != nil else { return }
            requestLocation(for: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self,
                  isFreshAndAccurate(location)
            else {
                return
            }
            let coordinate = RodiCoordinate(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            finish(isSupported(coordinate) ? .resolved(coordinate) : .unavailable)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            if (error as? CLError)?.code == .locationUnknown {
                return
            }
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

    @MainActor
    private func isFreshAndAccurate(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= maximumHorizontalAccuracy,
              let locationRequestStartedAt
        else {
            return false
        }

        return location.timestamp.timeIntervalSince(locationRequestStartedAt) >= -maximumLocationAge
    }
}
