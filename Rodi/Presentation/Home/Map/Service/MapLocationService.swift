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
    private var locationRequestID: UUID?
    private var headingContinuation: AsyncStream<Double>.Continuation?
    private var headingStreamID: UUID?
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
        let requestID = UUID()

        return await withTaskCancellationHandler(
            operation: {
                await withCheckedContinuation { continuation in
                    guard !Task.isCancelled, self.continuation == nil else {
                        continuation.resume(returning: .unavailable)
                        return
                    }

                    self.continuation = continuation
                    locationRequestID = requestID
                    locationRequestStartedAt = Date()
                    requestLocation(
                        for: locationManager.authorizationStatus,
                        requestID: requestID
                    )
                }
            },
            onCancel: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.finish(.unavailable, requestID: requestID)
                }
            }
        )
    }

    func headingUpdates() -> AsyncStream<Double> {
        let streamID = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            finishHeadingUpdates()
            headingContinuation = continuation
            headingStreamID = streamID

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.finishHeadingUpdates(streamID: streamID)
                }
            }

            guard CLLocationManager.headingAvailable() else {
                finishHeadingUpdates(streamID: streamID)
                return
            }

            locationManager.startUpdatingHeading()
        }
    }

    private func requestLocation(
        for status: CLAuthorizationStatus,
        requestID: UUID
    ) {
        guard locationRequestID == requestID else { return }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            scheduleLocationRequestTimeout(requestID: requestID)
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            finish(.permissionDenied(.denied), requestID: requestID)
        case .restricted:
            finish(.permissionDenied(.restricted), requestID: requestID)
        @unknown default:
            finish(.unavailable, requestID: requestID)
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

    private func finish(_ result: Result, requestID: UUID? = nil) {
        guard let continuation,
              requestID == nil || locationRequestID == requestID
        else {
            return
        }

        self.continuation = nil
        locationRequestID = nil
        locationRequestTimeoutTask?.cancel()
        locationRequestTimeoutTask = nil
        locationRequestStartedAt = nil
        locationManager.stopUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        continuation.resume(returning: result)
    }

    private func scheduleLocationRequestTimeout(requestID: UUID) {
        locationRequestTimeoutTask?.cancel()
        let timeoutNanoseconds = locationRequestTimeoutNanoseconds
        locationRequestTimeoutTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: timeoutNanoseconds)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.finish(.unavailable, requestID: requestID)
        }
    }

    private func finishHeadingUpdates(streamID: UUID? = nil) {
        guard streamID == nil || headingStreamID == streamID else { return }

        let continuation = headingContinuation
        headingContinuation = nil
        headingStreamID = nil
        locationManager.stopUpdatingHeading()
        continuation?.finish()
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
            guard let self, let requestID = locationRequestID else { return }
            requestLocation(for: status, requestID: requestID)
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
            finish(
                isSupported(coordinate) ? .resolved(coordinate) : .unavailable,
                requestID: locationRequestID
            )
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            if (error as? CLError)?.code == .locationUnknown {
                return
            }
            self?.finish(.unavailable, requestID: self?.locationRequestID)
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
