//
//  DrivePracticeLocationAdapter.swift
//  Rodi
//

import CoreLocation

/// Core Location과 DrivePractice 세션 정책 사이의 bridge다.
/// 권한·정밀 위치 요청, 위치 업데이트, 백그라운드 세션을 관리하고 이벤트만 상위에 전달한다.
@MainActor
final class DrivePracticeLocationAdapter: NSObject {
    private enum Policy {
        static let approachDesiredAccuracy = kCLLocationAccuracyHundredMeters
        static let approachDistanceFilter: CLLocationDistance = 100
        static let drivingDesiredAccuracy = kCLLocationAccuracyNearestTenMeters
        static let drivingDistanceFilter: CLLocationDistance = 20
    }

    private let locationManager = CLLocationManager()
    private let onLocation: (CLLocation) -> Void
    private let onFailure: (Error) -> Void
    private var backgroundActivitySession: AnyObject?

    init(
        onLocation: @escaping (CLLocation) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onLocation = onLocation
        self.onFailure = onFailure
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = Policy.approachDesiredAccuracy
        locationManager.distanceFilter = Policy.approachDistanceFilter
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
}


// MARK: - Core Logics
extension DrivePracticeLocationAdapter {
    
    var hasGrantedLocationAuthorization: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse
            || locationManager.authorizationStatus == .authorizedAlways
    }

    func locationPrerequisite() -> DrivePracticeStartResult? {
        guard CLLocationManager.locationServicesEnabled() else {
            return .unavailable("위치 서비스를 켠 뒤 연습 기록을 시작해주세요.")
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return .authorizationRequested
            
        case .authorizedWhenInUse, .authorizedAlways:
            break
            
        case .denied, .restricted:
            return .unavailable("위치 권한이 없어 이번 길안내에는 연습 기록이 포함되지 않아요.")
            
        @unknown default:
            return .unavailable("위치 권한 상태를 확인하지 못해 이번 길안내에는 연습 기록이 포함되지 않아요.")
        }

        guard locationManager.accuracyAuthorization == .fullAccuracy else {
            locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "DrivePractice")
            return .reducedAccuracyRequested
        }
        
        return nil
    }

    func startTracking(phase: DrivePracticePhase, isParking: Bool) {
        beginBackgroundActivitySession()
        updateTrackingPolicy(phase: phase, isParking: isParking)
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
    }

    func updateTrackingPolicy(phase: DrivePracticePhase, isParking: Bool) {
        if phase == .drivingCourse, !isParking {
            locationManager.desiredAccuracy = Policy.drivingDesiredAccuracy
            locationManager.distanceFilter = Policy.drivingDistanceFilter
            return
        }

        locationManager.desiredAccuracy = Policy.approachDesiredAccuracy
        locationManager.distanceFilter = Policy.approachDistanceFilter
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        endBackgroundActivitySession()
    }

    private func beginBackgroundActivitySession() {
        guard #available(iOS 17.0, *), backgroundActivitySession == nil else { return }
        backgroundActivitySession = CLBackgroundActivitySession()
    }

    private func endBackgroundActivitySession() {
        guard #available(iOS 17.0, *),
              let session = backgroundActivitySession as? CLBackgroundActivitySession
        else {
            backgroundActivitySession = nil
            return
        }

        session.invalidate()
        backgroundActivitySession = nil
    }
}


// MARK: Delegate
extension DrivePracticeLocationAdapter: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            self?.onLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            self?.onFailure(error)
        }
    }
}
