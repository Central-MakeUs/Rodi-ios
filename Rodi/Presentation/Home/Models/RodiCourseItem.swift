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

extension RodiCourseItem {
    /// `/places/coordinates`의 경량 마커 응답을 홈 지도용 모델로 변환한다.
    /// 상세 정보는 이후 `/places/{id}` 응답으로 보강한다.
    init(placeCoordinate: PlaceCoordinate) {
        id = placeCoordinate.id
        type = placeCoordinate.type == .course ? .course : .parking
        name = placeCoordinate.name
        address = placeCoordinate.address
        roadAddress = nil
        jibunAddress = nil
        lat = placeCoordinate.latitude
        lng = placeCoordinate.longitude
        rating = 0
        difficultyScore = 3
        tags = placeCoordinate.type == .course ? ["연습코스"] : ["주차"]
        summary = "상세 정보를 불러오는 중이에요."
        cautions = []
        recommendedTime = nil
        distanceKm = nil
        estimatedMinutes = nil
        parking = nil
        course = nil
    }

    /// `/places` 목록 응답을 기존 선택 상세 흐름과 연결하기 위한 임시 변환이다.
    /// 상세 경로와 주차장 부가 정보는 `/places/{id}` 연동 시 보강한다.
    init(placeListItem: PlaceListItem) {
        id = placeListItem.id
        type = placeListItem.type == .course ? .course : .parking
        name = placeListItem.name
        address = placeListItem.address
        roadAddress = nil
        jibunAddress = nil
        lat = placeListItem.latitude
        lng = placeListItem.longitude
        rating = 0
        difficultyScore = 3
        tags = placeListItem.type == .parking ? ["주차"] : placeListItem.practiceTypes
        summary = placeListItem.summary ?? ""
        cautions = []
        recommendedTime = nil
        distanceKm = placeListItem.distanceMeters.map { Double($0) / 1_000 }
        estimatedMinutes = nil
        parking = placeListItem.type == .parking
            ? RodiParkingInfo(
                managementNo: nil,
                parkingType: nil,
                capacity: placeListItem.capacity,
                isFree: nil,
                feeInfo: nil,
                operatingHours: nil,
                paymentMethods: nil,
                hasAccessibleSpace: nil,
                phone: nil,
                operator: nil,
                note: nil
            )
            : nil
        course = nil
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
