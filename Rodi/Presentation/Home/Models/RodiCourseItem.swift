//
//  RodiCourseItem.swift
//  Rodi
//

import Foundation

/// 홈 지도와 바텀싯에서 공통으로 사용하는 장소/코스 항목.
/// JSON의 `single`, `course`, `parking`을 하나의 리스트로 다루기 위한 도메인 모델이다.
struct RodiCourseItem: Decodable, Identifiable {
    let id: Int
    let type: RodiCourseType
    let name: String
    let address: String
    let roadAddress: String?
    let jibunAddress: String?
    let lat: Double
    let lng: Double
    let rating: Double
    let difficultyScore: Int
    let tags: [String]
    let summary: String
    let cautions: [String]
    let recommendedTime: String?
    let distanceKm: Double?
    let estimatedMinutes: Int?
    let parking: RodiParkingInfo?
    let course: RodiCourse?

    var coordinate: RodiCoordinate {
        RodiCoordinate(latitude: lat, longitude: lng)
    }

    var districtSummary: String {
        let parts = address.split(separator: " ").map(String.init)
        guard parts.count >= 2 else { return address }
        return parts.prefix(2).joined(separator: " ")
    }

    var roadAddressText: String {
        roadAddress?.nilIfBlank ?? address
    }

    var jibunAddressText: String {
        jibunAddress?.nilIfBlank ?? address
    }

    var difficultyTitle: String {
        switch difficultyScore {
        case ...1:
            "매우 쉬움"
        case 2:
            "쉬움"
        case 3:
            "보통"
        case 4:
            "어려움"
        default:
            "매우 어려움"
        }
    }

    var visibleTags: [String] {
        Array(tags.prefix(2))
    }

    var routeOverlayPoints: [RodiRouteOverlayPoint] {
        guard let points = course?.points.sorted(by: { $0.sequence < $1.sequence }) else {
            return []
        }

        return points.map {
            RodiRouteOverlayPoint(
                id: $0.id,
                sequence: $0.sequence,
                role: $0.role,
                name: $0.name,
                coordinate: $0.coordinate
            )
        }
    }

    var mapMarker: RodiMapMarker? {
        switch type {
        case .single, .course:
            RodiMapMarker(
                id: "course-\(id)",
                kind: .course,
                title: name,
                coordinate: coordinate
            )
        case .parking:
            RodiMapMarker(
                id: "parking-\(id)",
                kind: .parking,
                title: name,
                coordinate: coordinate
            )
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
