//
//  HomeDebugPlaceFixtures.swift
//  Rodi
//

import Foundation

#if DEBUG
enum HomeDebugPlaceFixtures {
    static let gasanTestCourseID = -9_001

    static let gasanTestCourse: RodiCourseItem = RodiCourseItem(placeDetail: gasanTestCourseDetail)

    static let gasanTestCourseDetail = PlaceDetail(
        id: gasanTestCourseID,
        type: .course,
        name: "가산동 테스트코스",
        address: "서울 금천구 가산동",
        latitude: 37.4746820,
        longitude: 126.8872366,
        practiceTypes: [PlacePracticeType.straight.rawValue],
        bookmarkCount: 0,
        isBookmarked: false,
        course: PlaceCourseDetail(
            summary: "테스트중인 직진코스",
            cautions: ["주의사항"],
            distanceMeters: 200,
            waypoints: [
                PlaceWaypoint(
                    type: "START",
                    sequence: 1,
                    latitude: 37.4746820,
                    longitude: 126.8872366,
                    name: "가산동 출발지"
                ),
                PlaceWaypoint(
                    type: "END",
                    sequence: 2,
                    latitude: 37.4757878,
                    longitude: 126.8892964,
                    name: "가산동 도착지"
                )
            ]
        ),
        parking: nil
    )

    static func detail(for placeID: Int) -> PlaceDetail? {
        placeID == gasanTestCourseID ? gasanTestCourseDetail : nil
    }
}
#endif
