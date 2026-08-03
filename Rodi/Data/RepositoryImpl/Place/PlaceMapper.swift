//
//  PlaceMapper.swift
//  Rodi
//

import Foundation

enum PlaceMapper {
    static func coordinate(
        from dto: PlaceCoordinateDTO
    ) throws(NetworkError) -> PlaceCoordinate {
        PlaceCoordinate(
            id: dto.id,
            type: try placeType(from: dto.type),
            name: dto.name,
            address: dto.address,
            latitude: dto.lat,
            longitude: dto.lng
        )
    }

    static func cursorPage(
        from dto: PlaceCursorPageDTO
    ) throws(NetworkError) -> PlaceCursorPage {
        PlaceCursorPage(
            items: try dto.items.map(listItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: dto.totalCount
        )
    }

    static func relatedSearchResult(
        from dto: PlaceRelatedSearchDTO
    ) throws(NetworkError) -> PlaceRelatedSearchResult {
        PlaceRelatedSearchResult(
            regions: dto.regions,
            places: try cursorPage(from: dto.places)
        )
    }

    static func detail(
        from dto: PlaceDetailDTO
    ) throws(NetworkError) -> PlaceDetail {
        PlaceDetail(
            id: dto.id,
            type: try placeType(from: dto.type),
            name: dto.name,
            address: dto.address,
            latitude: dto.lat,
            longitude: dto.lng,
            practiceTypes: dto.practiceTypes ?? [],
            bookmarkCount: dto.bookmarkCount ?? 0,
            isBookmarked: dto.isBookmarked ?? false,
            course: dto.course?.domain,
            parking: dto.parking?.domain
        )
    }
}

private extension PlaceMapper {
    static func listItem(
        from dto: PlaceListItemDTO
    ) throws(NetworkError) -> PlaceListItem {
        PlaceListItem(
            id: dto.id,
            type: try placeType(from: dto.type),
            name: dto.name,
            address: dto.address,
            latitude: dto.lat,
            longitude: dto.lng,
            distanceFromMeMeters: dto.distanceFromMe,
            practiceTypes: dto.practiceTypes ?? [],
            summary: dto.description,
            distanceMeters: dto.distanceMeters,
            capacity: dto.capacity,
            openTime: dto.openTime
        )
    }

    static func placeType(
        from serverValue: String
    ) throws(NetworkError) -> PlaceType {
        guard let value = PlaceType(rawValue: serverValue) else {
            throw .apiError(
                code: "PLACE_INVALID_TYPE",
                message: "장소 유형을 확인하지 못했어요."
            )
        }
        return value
    }
}

private extension PlaceCourseDetailDTO {
    var domain: PlaceCourseDetail {
        PlaceCourseDetail(
            summary: description,
            cautions: cautions ?? [],
            distanceMeters: distanceMeters,
            waypoints: (waypoints ?? []).map(\.domain)
        )
    }
}

private extension PlaceWaypointDTO {
    var domain: PlaceWaypoint {
        PlaceWaypoint(
            type: type,
            sequence: sequence,
            latitude: lat,
            longitude: lng,
            name: name
        )
    }
}

private extension PlaceParkingDetailDTO {
    var domain: PlaceParkingDetail {
        PlaceParkingDetail(
            roadAddress: roadAddress,
            lotAddress: lotAddress,
            managementNumber: managementNo,
            parkingType: parkingType,
            capacity: capacity,
            isFree: isFree,
            feeInfo: feeInfo?.domain,
            operatingHours: operatingHours?.domain
        )
    }
}

private extension PlaceFeeInfoDTO {
    var domain: PlaceFeeInfo {
        PlaceFeeInfo(
            baseMinutes: baseMinutes,
            baseFee: baseFee,
            addUnitMinutes: addUnitMinutes,
            addUnitFee: addUnitFee,
            dayTicketHours: dayTicketHours,
            dayTicketFee: dayTicketFee,
            monthlyFee: monthlyFee
        )
    }
}

private extension PlaceOperatingHoursDTO {
    var domain: PlaceOperatingHours {
        PlaceOperatingHours(
            weekday: weekday,
            saturday: saturday,
            holiday: holiday
        )
    }
}
