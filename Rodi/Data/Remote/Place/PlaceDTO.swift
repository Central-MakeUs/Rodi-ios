//
//  PlaceDTO.swift
//  Rodi
//

import Foundation

struct PlaceCoordinateDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
}

struct PlaceListItemDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let distanceFromMe: Int?
    let practiceTypes: [String]?
    let description: String?
    let distanceMeters: Int?
    let capacity: Int?
    let openTime: String?
}

struct PlaceCursorPageDTO: Decodable {
    let items: [PlaceListItemDTO]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct PlaceDetailDTO: Decodable {
    let id: Int
    let type: String
    let name: String
    let address: String
    let lat: Double
    let lng: Double
    let practiceTypes: [String]?
    let bookmarkCount: Int?
    let isBookmarked: Bool?
    let course: PlaceCourseDetailDTO?
    let parking: PlaceParkingDetailDTO?
}

struct PlaceCourseDetailDTO: Decodable {
    let description: String?
    let cautions: [String]?
    let distanceMeters: Int?
    let waypoints: [PlaceWaypointDTO]?
}

struct PlaceWaypointDTO: Decodable {
    let type: String
    let sequence: Int
    let lat: Double
    let lng: Double
    let name: String?
}

struct PlaceParkingDetailDTO: Decodable {
    let roadAddress: String?
    let lotAddress: String?
    let managementNo: String?
    let parkingType: String?
    let capacity: Int?
    let isFree: Bool?
    let feeInfo: PlaceFeeInfoDTO?
    let operatingHours: PlaceOperatingHoursDTO?
}

struct PlaceFeeInfoDTO: Decodable {
    let baseMinutes: Int?
    let baseFee: Int?
    let addUnitMinutes: Int?
    let addUnitFee: Int?
    let dayTicketHours: Int?
    let dayTicketFee: Int?
    let monthlyFee: Int?
}

struct PlaceOperatingHoursDTO: Decodable {
    let weekday: String?
    let saturday: String?
    let holiday: String?
}
