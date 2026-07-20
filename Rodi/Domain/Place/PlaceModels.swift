//
//  PlaceModels.swift
//  Rodi
//

import Foundation

enum PlaceType: String, Equatable {
    case course = "COURSE"
    case parking = "PARKING"
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
