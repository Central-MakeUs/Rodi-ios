//
//  RodiCoursePointRole.swift
//  Rodi
//

import Foundation

/// 코스 포인트의 길안내 역할.
enum RodiCoursePointRole: String, Decodable {
    case start = "START"
    case waypoint = "WAYPOINT"
    case end = "END"
}
