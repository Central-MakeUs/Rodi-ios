import XCTest
@testable import Rodi

final class PracticeMeasurementStoreTests: XCTestCase {

    private let measurementKey = "rodi.practice-measurement"
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "PracticeMeasurementStoreTests")!
        userDefaults.removePersistentDomain(forName: "PracticeMeasurementStoreTests")
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "PracticeMeasurementStoreTests")
        userDefaults = nil
        super.tearDown()
    }

    func testLoadMigratesLegacyPayloadToCurrentSchema() throws {
        let measurement = makeMeasurement(status: .certificationPendingVisit)
        userDefaults.set(try JSONEncoder().encode(measurement), forKey: measurementKey)

        let restored = PracticeMeasurementStore(userDefaults: userDefaults).load()

        XCTAssertEqual(restored, measurement)
        let migratedData = try XCTUnwrap(userDefaults.data(forKey: measurementKey))
        let migratedPayload = try XCTUnwrap(JSONSerialization.jsonObject(with: migratedData) as? [String: Any])
        XCTAssertEqual(migratedPayload["schemaVersion"] as? Int, 1)
    }

    func testLoadClearsCorruptPayload() {
        userDefaults.set(Data("corrupt".utf8), forKey: measurementKey)

        XCTAssertNil(PracticeMeasurementStore(userDefaults: userDefaults).load())
        XCTAssertNil(userDefaults.data(forKey: measurementKey))
    }

    func testClearRemovesStoredMeasurement() {
        let store = PracticeMeasurementStore(userDefaults: userDefaults)
        store.save(makeMeasurement(status: .certified))

        store.clear()

        XCTAssertNil(store.load())
    }

    private func makeMeasurement(status: PracticeMeasurementStatus) -> PracticeMeasurement {
        .init(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            placeID: 1,
            placeName: "연습 코스",
            mode: .gpsTracking,
            externalHandoffAt: Date(timeIntervalSince1970: 0),
            status: status
        )
    }
}
