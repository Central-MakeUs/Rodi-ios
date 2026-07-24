//
//  PlaceModels.swift
//  Rodi
//

import Foundation

enum PlaceType: String, Equatable {
    case course = "COURSE"
    case parking = "PARKING"
}

/// `/api/v1/places`가 전달하는 코스 연습 유형이다.
/// 서버에 새 유형이 추가되어도 목록은 원문을 유지해 표시한다.
enum PlacePracticeType: String, CaseIterable, Equatable, Hashable {
    case uTurn = "U_TURN"
    case leftRightTurn = "LEFT_RIGHT_TURN"
    case parking = "PARKING"
    case laneChange = "LANE_CHANGE"
    case intersection = "INTERSECTION"
    case roundabout = "ROUNDABOUT"
    case unprotectedLeftTurn = "UNPROTECTED_LEFT_TURN"
    case highwayEntry = "HIGHWAY_ENTRY"
    case cornering = "CORNERING"
    case narrowRoad = "NARROW_ROAD"
    case multilane = "MULTILANE"
    case merging = "MERGING"
    case straight = "STRAIGHT"
    case registerCourse = "REGISTER_COURSE"
    case writeReview = "WRITE_REVIEW"
    case shareCourse = "SHARE_COURSE"

    nonisolated var displayName: String {
        switch self {
        case .uTurn: "유턴"
        case .leftRightTurn: "좌우회전"
        case .parking: "주차"
        case .laneChange: "차선변경"
        case .intersection: "교차로"
        case .roundabout: "회전교차로"
        case .unprotectedLeftTurn: "비보호좌회전"
        case .highwayEntry: "고속도로"
        case .cornering: "코너링"
        case .narrowRoad: "좁은도로"
        case .multilane: "다차로주행"
        case .merging: "합류"
        case .straight: "직선주행"
        case .registerCourse: "코스등록"
        case .writeReview: "리뷰작성"
        case .shareCourse: "추천코스공유"
        }
    }

    nonisolated static func displayName(for rawValue: String) -> String {
        Self(rawValue: rawValue)?.displayName ?? rawValue
    }
}

struct PlaceCoordinate: Equatable, Identifiable {
    let id: Int
    let type: PlaceType
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

struct PlaceViewport: Equatable {
    let southWestLatitude: Double
    let southWestLongitude: Double
    let northEastLatitude: Double
    let northEastLongitude: Double
}

struct PlaceListQuery: Equatable {
    let viewport: PlaceViewport
    let currentLatitude: Double
    let currentLongitude: Double
    let size: Int
    let cursor: String?

    init(
        viewport: PlaceViewport,
        currentLatitude: Double,
        currentLongitude: Double,
        size: Int = 20,
        cursor: String? = nil
    ) {
        self.viewport = viewport
        self.currentLatitude = currentLatitude
        self.currentLongitude = currentLongitude
        self.size = size
        self.cursor = cursor
    }
}

/// `/api/v1/places/bookmarks`의 커서 페이지 요청입니다.
struct PlaceBookmarkListQuery: Equatable {
    let size: Int
    let cursor: String?

    init(size: Int = 20, cursor: String? = nil) {
        self.size = size
        self.cursor = cursor
    }
}

struct PlaceListItem: Equatable, Identifiable {
    let id: Int
    let type: PlaceType
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let distanceFromMeMeters: Int?
    let practiceTypes: [String]
    let summary: String?
    let distanceMeters: Int?
    let capacity: Int?
    let openTime: String?
}

struct PlaceCursorPage: Equatable {
    let items: [PlaceListItem]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct PlaceDetail: Equatable, Identifiable {
    let id: Int
    let type: PlaceType
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let practiceTypes: [String]
    let bookmarkCount: Int
    let isBookmarked: Bool
    let course: PlaceCourseDetail?
    let parking: PlaceParkingDetail?
}

struct PlaceCourseDetail: Equatable {
    let summary: String?
    let cautions: [String]
    let distanceMeters: Int?
    let waypoints: [PlaceWaypoint]
}

struct PlaceWaypoint: Equatable {
    let type: String
    let sequence: Int
    let latitude: Double
    let longitude: Double
    let name: String?
}

struct PlaceParkingDetail: Equatable {
    let roadAddress: String?
    let lotAddress: String?
    let managementNumber: String?
    let parkingType: String?
    let capacity: Int?
    let isFree: Bool?
    let feeInfo: PlaceFeeInfo?
    let operatingHours: PlaceOperatingHours?
}

struct PlaceFeeInfo: Equatable {
    let baseMinutes: Int?
    let baseFee: Int?
    let addUnitMinutes: Int?
    let addUnitFee: Int?
    let dayTicketHours: Int?
    let dayTicketFee: Int?
    let monthlyFee: Int?
}

struct PlaceOperatingHours: Equatable {
    let weekday: String?
    let saturday: String?
    let holiday: String?
}
