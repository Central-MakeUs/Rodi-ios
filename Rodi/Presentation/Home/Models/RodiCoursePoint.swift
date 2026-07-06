//
//  RodiCoursePoint.swift
//  Rodi
//

import Foundation

/// 코스 상세에서 사용하는 출발지, 경유지, 도착지 좌표.
struct RodiCoursePoint: Decodable, Identifiable {
    let id: Int
    let sequence: Int
    let role: RodiCoursePointRole
    let name: String
    let address: String
    let lat: Double
    let lng: Double

    var coordinate: RodiCoordinate {
        RodiCoordinate(latitude: lat, longitude: lng)
    }
}
