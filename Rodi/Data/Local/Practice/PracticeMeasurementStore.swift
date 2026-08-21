import Foundation

/// 연습 측정의 저장 표현과 schema migration을 소유한다.
struct PracticeMeasurementStore: PracticeMeasurementStoring {
    private enum Key {
        static let measurement = "rodi.practice-measurement"
        static let legacyPrompt = "rodi.practice-return-prompt"
    }

    private enum Schema {
        static let current = 1
    }

    private struct Payload: Codable {
        let schemaVersion: Int?
        let id: UUID
        let placeID: Int
        let placeName: String
        let placeType: PracticeMeasurementPlaceType?
        let mode: PracticeMeasurementMode
        let externalHandoffAt: Date
        let lastRodiInactiveAt: Date?
        let status: PracticeMeasurementStatus
        let certifiedDistanceMeters: Int?
        let practiceID: Int?

        init(measurement: PracticeMeasurement) {
            schemaVersion = Schema.current
            id = measurement.id
            placeID = measurement.placeID
            placeName = measurement.placeName
            placeType = measurement.placeType
            mode = measurement.mode
            externalHandoffAt = measurement.externalHandoffAt
            lastRodiInactiveAt = measurement.lastRodiInactiveAt
            status = measurement.status
            certifiedDistanceMeters = measurement.certifiedDistanceMeters
            practiceID = measurement.practiceID
        }

        var measurement: PracticeMeasurement {
            .init(
                id: id,
                placeID: placeID,
                placeName: placeName,
                placeType: placeType ?? .course,
                mode: mode,
                externalHandoffAt: externalHandoffAt,
                status: status
            )
            .updating(
                lastRodiInactiveAt: lastRodiInactiveAt,
                certifiedDistanceMeters: certifiedDistanceMeters,
                practiceID: practiceID
            )
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        userDefaults.removeObject(forKey: Key.legacyPrompt)
    }

    func load() -> PracticeMeasurement? {
        guard let data = userDefaults.data(forKey: Key.measurement) else { return nil }

        do {
            let payload = try JSONDecoder().decode(Payload.self, from: data)
            guard payload.schemaVersion == nil || payload.schemaVersion == Schema.current else {
                RodiLogger.warning("Practice measurement restore skipped: unsupported schema")
                clear()
                return nil
            }

            let measurement = payload.measurement
            if payload.schemaVersion == nil {
                save(measurement)
            }
            return measurement
        } catch {
            RodiLogger.warning("Practice measurement restore failed")
            clear()
            return nil
        }
    }

    func save(_ measurement: PracticeMeasurement) {
        do {
            let data = try JSONEncoder().encode(Payload(measurement: measurement))
            userDefaults.set(data, forKey: Key.measurement)
        } catch {
            RodiLogger.warning("Practice measurement save failed")
        }
    }

    func remove(_ measurement: PracticeMeasurement) {
        guard load()?.id == measurement.id else { return }
        clear()
    }

    func clear() {
        userDefaults.removeObject(forKey: Key.measurement)
    }
}

private extension PracticeMeasurement {
    func updating(
        lastRodiInactiveAt: Date?,
        certifiedDistanceMeters: Int?,
        practiceID: Int?
    ) -> Self {
        var measurement = self
        measurement.lastRodiInactiveAt = lastRodiInactiveAt
        measurement.certifiedDistanceMeters = certifiedDistanceMeters
        measurement.practiceID = practiceID
        return measurement
    }
}
