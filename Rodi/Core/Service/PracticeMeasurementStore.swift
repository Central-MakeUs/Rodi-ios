//
//  PracticeMeasurementStore.swift
//  Rodi
//

import Foundation

enum PracticeMeasurementMode: String, Codable, Equatable {
    case gpsTracking
    case routeOnly
}

enum PracticeMeasurementPlaceType: String, Codable, Equatable {
    case course
    case parking
}

enum PracticeMeasurementStatus: String, Codable, Equatable {
    case awaitingReturn
    case tracking
    case certificationPendingRegistration
    case certificationPendingVisit
    case certified
}

/// 측정 재진입과 방문 인증에 필요한 최소 정보만 저장한다.
/// 사용자의 원본 GPS 좌표는 저장하지 않는다.
struct PracticeMeasurement: Codable, Equatable, Identifiable {
    let id: UUID
    let placeID: Int
    let placeName: String
    /// 누락된 기존 저장값은 코스로 해석한다.
    let placeType: PracticeMeasurementPlaceType?
    let mode: PracticeMeasurementMode
    let externalHandoffAt: Date
    var lastRodiInactiveAt: Date?
    var status: PracticeMeasurementStatus
    var certifiedDistanceMeters: Int?
    var practiceID: Int?

    init(
        id: UUID = UUID(),
        placeID: Int,
        placeName: String,
        placeType: PracticeMeasurementPlaceType = .course,
        mode: PracticeMeasurementMode,
        externalHandoffAt: Date = .now,
        status: PracticeMeasurementStatus
    ) {
        self.id = id
        self.placeID = placeID
        self.placeName = placeName
        self.placeType = placeType
        self.mode = mode
        self.externalHandoffAt = externalHandoffAt
        self.lastRodiInactiveAt = externalHandoffAt
        self.status = status
    }

    var isActiveTracking: Bool {
        mode == .gpsTracking && status == .tracking
    }

    var isParking: Bool {
        placeType == .parking
    }

    var isReviewEligible: Bool {
        status == .certified
            || (mode == .routeOnly && status == .awaitingReturn && lastRodiInactiveAt != nil)
    }
}

protocol PracticeMeasurementStoring {
    func load() -> PracticeMeasurement?
    func save(_ measurement: PracticeMeasurement)
    func remove(_ measurement: PracticeMeasurement)
    func clear()
}

struct PracticeMeasurementStore: PracticeMeasurementStoring {
    private enum Key {
        static let measurement = "rodi.practice-measurement"
        static let legacyPrompt = "rodi.practice-return-prompt"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        // 이전 버전의 즉시 후기 팝업 후보는 시간·인증 정보를 알 수 없어 승계하지 않는다.
        userDefaults.removeObject(forKey: Key.legacyPrompt)
    }

    func load() -> PracticeMeasurement? {
        guard let data = userDefaults.data(forKey: Key.measurement) else { return nil }
        return try? JSONDecoder().decode(PracticeMeasurement.self, from: data)
    }

    func save(_ measurement: PracticeMeasurement) {
        guard let data = try? JSONEncoder().encode(measurement) else { return }
        userDefaults.set(data, forKey: Key.measurement)
    }

    func remove(_ measurement: PracticeMeasurement) {
        guard load()?.id == measurement.id else { return }
        clear()
    }

    func clear() {
        userDefaults.removeObject(forKey: Key.measurement)
    }
}
