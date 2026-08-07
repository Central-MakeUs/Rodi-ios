//
//  RodiParkingInfo.swift
//  Rodi
//

import Foundation

struct RodiParkingInfo: Decodable {
    let managementNo: String?
    let parkingType: String?
    let capacity: Int?
    let isFree: Bool?
    let feeInfo: RodiParkingFeeInfo?
    let operatingHours: RodiParkingOperatingHours?
    let paymentMethods: [String]?
    let hasAccessibleSpace: Bool?
    let phone: String?
    let `operator`: String?
    let note: String?
}

struct RodiParkingFeeInfo: Decodable {
    let baseMinutes: Int?
    let baseFee: Int?
    let addUnitMinutes: Int?
    let addUnitFee: Int?
    let dayTicketHours: Int?
    let dayTicketFee: Int?
    let monthlyFee: Int?
}

struct RodiParkingOperatingHours: Decodable {
    let weekday: String?
    let saturday: String?
    let holiday: String?
}
