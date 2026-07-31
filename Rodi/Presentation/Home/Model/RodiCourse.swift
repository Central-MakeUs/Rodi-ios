//
//  RodiCourse.swift
//  Rodi
//

import Foundation

/// 경로형 코스가 갖는 상세 경유점 묶음.
/// 초기 홈 마커에는 사용하지 않고, 코스 선택 이후 route overlay와 외부 길안내에 사용한다.
struct RodiCourse: Decodable {
    let points: [RodiCoursePoint]
}
