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
    }
}

protocol PracticeMeasurementStoring {
    func load() -> PracticeMeasurement?
    func save(_ measurement: PracticeMeasurement)
    func remove(_ measurement: PracticeMeasurement)
    func clear()
}
