//
//  PracticeTrackingService.swift
//  Rodi
//

import Combine
import CoreLocation
import Foundation

@MainActor
final class PracticeTrackingService: NSObject, ObservableObject {
    static let shared = PracticeTrackingService()

    private enum Policy {
        static let maximumHorizontalAccuracy: CLLocationAccuracy = 60
        static let routeCorridorMeters = 50.0
        static let minimumDrivingSeconds: TimeInterval = 180
        static let maximumSampleGap: TimeInterval = 60
        static let maximumForwardMetersPerSecond = 45.0
        static let forwardDistanceToleranceMeters = 80.0
    }

    @Published private(set) var session: PracticeTrackingSession?

    private let locationManager = CLLocationManager()
    private let sessionStore: PracticeTrackingSessionStore
    private var backgroundActivitySession: AnyObject?
    private var didStartSessionInCurrentProcess = false

    private override init() {
        sessionStore = PracticeTrackingSessionStore()
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 20
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        session = sessionStore.load()
    }

    func start(course: RodiCourseItem, routePath: [RodiCoordinate]) -> PracticeTrackingStartResult {
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
            locationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "PracticeTracking")
            return .reducedAccuracyRequested
        }

        guard routePath.count >= 2 else {
            return .unavailable("코스 경로를 준비하지 못했어요. 잠시 후 다시 시도해주세요.")
        }

        if session?.phase.isTerminal == false {
            cancel()
        }

        let session = PracticeTrackingSession(
            id: UUID(),
            courseID: course.id,
            courseName: course.name,
            routePath: routePath,
            cumulativeRouteDistanceMeters: PracticeRouteMatcher.cumulativeDistance(for: routePath),
            startedAt: .now,
            phase: .headingToCourse,
            drivingStartedAt: nil,
            lastAcceptedLocationAt: nil,
            courseProgress: 0,
            activeDrivingSeconds: 0,
            matchedSampleCount: 0,
            initialDistanceToCourseStartMeters: nil,
            distanceToCourseStartMeters: nil,
            lastMatchedLocationAt: nil,
            initialMatchedRouteDistanceMeters: nil,
            furthestMatchedRouteDistanceMeters: nil,
            drivenRouteDistanceMeters: nil,
            completedAt: nil
        )

        self.session = session
        sessionStore.save(session)
        didStartSessionInCurrentProcess = true
        beginBackgroundActivitySession()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startLiveActivity(for: session)
        syncLiveActivity(session, force: true)
        RodiLogger.info("Practice tracking started sessionID=\(session.id.uuidString), courseID=\(course.id)")
        return .started
    }

    func restoreIfNeeded() {
        guard var session, !session.phase.isTerminal else { return }
        guard didStartSessionInCurrentProcess else {
            session.phase = .interrupted
            self.session = session
            sessionStore.save(session)
            cancelLiveActivity()
            RodiLogger.info("Practice tracking interrupted after process restart sessionID=\(session.id.uuidString)")
            return
        }

        guard locationManager.authorizationStatus == .authorizedWhenInUse
                || locationManager.authorizationStatus == .authorizedAlways
        else { return }

        beginBackgroundActivitySession()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        startLiveActivity(for: session)
        syncLiveActivity(session, force: true)
        RodiLogger.info("Practice tracking restored sessionID=\(session.id.uuidString)")
    }

    func cancel() {
        guard var session, !session.phase.isTerminal else { return }
        session.phase = .cancelled
        self.session = session
        sessionStore.save(session)
        cancelLiveActivity()
        stopLocationUpdates()
        endBackgroundActivitySession()
        didStartSessionInCurrentProcess = false
        RodiLogger.info("Practice tracking cancelled sessionID=\(session.id.uuidString)")
    }

    private func receive(_ location: CLLocation) {
        guard var session, !session.phase.isTerminal else { return }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= Policy.maximumHorizontalAccuracy,
              abs(location.timestamp.timeIntervalSinceNow) < 15
        else {
            return
        }

        let currentCoordinate = RodiCoordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        guard let start = session.routePath.first else { return }

        let startDistance = PracticeRouteMatcher.distance(from: currentCoordinate, to: start)
        if session.phase == .headingToCourse, session.initialDistanceToCourseStartMeters == nil {
            session.initialDistanceToCourseStartMeters = startDistance
        }
        session.distanceToCourseStartMeters = startDistance

        session.lastAcceptedLocationAt = location.timestamp

        guard let match = PracticeRouteMatcher.match(
            location: location,
            path: session.routePath,
            cumulativeDistanceMeters: session.cumulativeRouteDistanceMeters
        ), match.distanceToRouteMeters <= Policy.routeCorridorMeters
        else {
            self.session = session
            sessionStore.save(session)
            syncLiveActivity(session)
            return
        }

        if session.phase == .headingToCourse {
            session.phase = .drivingCourse
            session.drivingStartedAt = location.timestamp
            session.lastMatchedLocationAt = location.timestamp
            session.initialMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.furthestMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.courseProgress = match.progress
            RodiLogger.info(
                "Practice tracking entered course sessionID=\(session.id.uuidString), progress=\(match.progress)"
            )
        }

        updateDrivingProgress(&session, match: match, timestamp: location.timestamp)

        if session.activeDrivingSeconds >= Policy.minimumDrivingSeconds,
           session.drivenRouteDistance >= session.requiredDrivingDistanceMeters,
           session.directionalAdvanceMeters >= session.requiredDirectionalAdvanceMeters {
            session.phase = .completed
            session.completedAt = location.timestamp
            stopLocationUpdates()
            endBackgroundActivitySession()
            didStartSessionInCurrentProcess = false
            finishLiveActivity(session)
            RodiLogger.info(
                "Practice tracking completed sessionID=\(session.id.uuidString), progress=\(session.courseProgress), seconds=\(session.activeDrivingSeconds)"
            )
        }

        self.session = session
        sessionStore.save(session)
        syncLiveActivity(session)
    }

    private func updateDrivingProgress(
        _ session: inout PracticeTrackingSession,
        match: PracticeRouteMatch,
        timestamp: Date
    ) {
        guard session.phase == .drivingCourse else { return }

        defer {
            session.lastMatchedLocationAt = timestamp
            session.matchedSampleCount += 1
        }

        guard let previousTimestamp = session.lastMatchedLocationAt,
              let furthestDistance = session.furthestMatchedRouteDistanceMeters
        else {
            session.initialMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.furthestMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
            session.courseProgress = match.progress
            return
        }

        let elapsedSeconds = min(
            max(0, timestamp.timeIntervalSince(previousTimestamp)),
            Policy.maximumSampleGap
        )
        session.activeDrivingSeconds += elapsedSeconds

        let forwardDistance = match.distanceAlongRouteMeters - furthestDistance
        let maximumPlausibleAdvance =
            (elapsedSeconds * Policy.maximumForwardMetersPerSecond) + Policy.forwardDistanceToleranceMeters
        guard forwardDistance > 0, forwardDistance <= maximumPlausibleAdvance else { return }

        session.furthestMatchedRouteDistanceMeters = match.distanceAlongRouteMeters
        session.drivenRouteDistanceMeters = (session.drivenRouteDistanceMeters ?? 0) + forwardDistance
        session.courseProgress = min(
            max(match.progress, session.courseProgress),
            1
        )
    }

    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
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

    private func startLiveActivity(for session: PracticeTrackingSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.start(for: session)
    }

    private func syncLiveActivity(_ session: PracticeTrackingSession, force: Bool = false) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.sync(session, force: force)
    }

    private func finishLiveActivity(_ session: PracticeTrackingSession) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.finish(session)
    }

    private func cancelLiveActivity() {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.shared.cancel()
    }
}

extension PracticeTrackingService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            receive(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            RodiLogger.warning("Practice tracking location failed: \(error.localizedDescription)")
        }
    }
}
