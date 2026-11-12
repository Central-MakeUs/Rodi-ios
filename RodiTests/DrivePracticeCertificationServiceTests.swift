import XCTest
@testable import Rodi

@MainActor
final class DrivePracticeCertificationServiceTests: XCTestCase {
    func testPendingRegistrationBecomesCertifiedAndNotifiesOnce() {
        let store = MeasurementStoreStub(measurement: makeMeasurement())
        let repository = PracticeRepositoryStub()
        var certificationCount = 0
        let certified = expectation(description: "certified")
        let service = DrivePracticeCertificationService(
            practiceRepository: repository,
            measurementStore: store,
            didCertify: {
                certificationCount += 1
                certified.fulfill()
            }
        )

        service.retryIfNeeded()

        wait(for: [certified], timeout: 1)
        XCTAssertEqual(store.measurement?.status, .certified)
        XCTAssertEqual(store.measurement?.practiceID, 101)
        XCTAssertEqual(certificationCount, 1)
    }

    func testFailureKeepsPendingMeasurementAndDoesNotNotify() {
        let store = MeasurementStoreStub(measurement: makeMeasurement())
        let repository = PracticeRepositoryStub(registerError: .networkUnavailable)
        let certified = expectation(description: "not certified")
        certified.isInverted = true
        let service = DrivePracticeCertificationService(
            practiceRepository: repository,
            measurementStore: store,
            didCertify: { certified.fulfill() }
        )

        service.retryIfNeeded()

        wait(for: [certified], timeout: 0.1)
        XCTAssertEqual(store.measurement?.status, .certificationPendingRegistration)
    }

    func testCancelledRequestCannotUpdateMeasurementOrNotify() {
        let store = MeasurementStoreStub(measurement: makeMeasurement())
        let registrationStarted = expectation(description: "registration started")
        let repository = PracticeRepositoryStub(
            delaysRegistration: true,
            onRegisterStarted: { registrationStarted.fulfill() }
        )
        let certified = expectation(description: "not certified")
        certified.isInverted = true
        let service = DrivePracticeCertificationService(
            practiceRepository: repository,
            measurementStore: store,
            didCertify: { certified.fulfill() }
        )

        service.retryIfNeeded()
        wait(for: [registrationStarted], timeout: 1)
        service.cancel()

        wait(for: [certified], timeout: 0.1)
        XCTAssertEqual(store.measurement?.status, .certificationPendingRegistration)
        XCTAssertNil(store.measurement?.practiceID)
    }

    private func makeMeasurement() -> PracticeMeasurement {
        var measurement = PracticeMeasurement(
            placeID: 10,
            placeName: "테스트 코스",
            mode: .gpsTracking,
            status: .certificationPendingRegistration
        )
        measurement.certifiedDistanceMeters = 1_000
        return measurement
    }
}

private final class MeasurementStoreStub: PracticeMeasurementStoring {
    var measurement: PracticeMeasurement?

    init(measurement: PracticeMeasurement?) {
        self.measurement = measurement
    }

    func load() -> PracticeMeasurement? { measurement }
    func save(_ measurement: PracticeMeasurement) { self.measurement = measurement }
    func remove(_ measurement: PracticeMeasurement) { self.measurement = nil }
    func clear() { measurement = nil }
}

private final class PracticeRepositoryStub: PracticeRepository {
    private let registerError: NetworkError?
    private let delaysRegistration: Bool
    private let onRegisterStarted: () -> Void

    init(
        registerError: NetworkError? = nil,
        delaysRegistration: Bool = false,
        onRegisterStarted: @escaping () -> Void = {}
    ) {
        self.registerError = registerError
        self.delaysRegistration = delaysRegistration
        self.onRegisterStarted = onRegisterStarted
    }

    func register(placeID: Int) async throws(NetworkError) -> PracticeRegistration {
        onRegisterStarted()
        if delaysRegistration {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        if let registerError { throw registerError }
        return .init(practiceID: 101, status: nil, visitCount: nil, requiredDistanceMeters: nil)
    }

    func recordVisit(practiceID: Int, certifiedDistanceMeters: Int?) async throws(NetworkError) -> PracticeVisit {
        .init(
            visitCount: 1,
            addedCertifiedDistanceMeters: certifiedDistanceMeters ?? 0,
            requiredDistanceMeters: 0,
            isCertifiedNow: true,
            totalDistanceKm: 1,
            levelUp: false,
            newLevel: nil
        )
    }

    func fetchMyPractices(query: MyPracticeQuery) async throws(NetworkError) -> MyPracticePage { fatalError() }
    func fetchSkipReasonForm() async throws(NetworkError) -> PracticeSkipReasonForm { fatalError() }
    func submitSkipReason(practiceID: Int, reasonCode: String, detail: String?) async throws(NetworkError) {}
}
