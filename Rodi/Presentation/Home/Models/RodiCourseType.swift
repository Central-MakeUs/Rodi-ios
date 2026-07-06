//
//  RodiCourseType.swift
//  Rodi
//

import Foundation

/// 홈 JSON 항목의 표시 유형.
/// `course`는 경로형 코스, `single`과 `parking`은 단일 좌표 항목으로 처리한다.
enum RodiCourseType: String, Decodable {
    case single
    case course
    case parking
}
