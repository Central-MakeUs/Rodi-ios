//
//  PlaceRepositoryImpl.swift
//  Rodi
//

import Foundation

final class PlaceRepositoryImpl: PlaceRepository {
    private let publicNetworkManager: NetworkManager
    private let authenticatedNetworkManager: NetworkManager

    init(
        publicNetworkManager: NetworkManager,
        authenticatedNetworkManager: NetworkManager
    ) {
        self.publicNetworkManager = publicNetworkManager
        self.authenticatedNetworkManager = authenticatedNetworkManager
    }

    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinate] {
        let response = try await publicNetworkManager.request(
            PlaceTarget.coordinates,
            as: ServerResponse<[PlaceCoordinateDTO]>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        var coordinates: [PlaceCoordinate] = []
        for item in data {
            coordinates.append(try mapCoordinate(item))
        }
        return coordinates
    }

    func fetchPlaces(query: PlaceListQuery) async throws(NetworkError) -> PlaceCursorPage {
        let response = try await publicNetworkManager.request(
            PlaceTarget.list(query),
            as: ServerResponse<PlaceCursorPageDTO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return try mapCursorPage(data)
    }

    func fetchBookmarkedPlaces(query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPage {
        let response = try await authenticatedNetworkManager.request(
            PlaceTarget.bookmarks(query),
            as: ServerResponse<PlaceCursorPageDTO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return try mapCursorPage(data)
    }

    func fetchPlaceDetail(id: Int) async throws(NetworkError) -> PlaceDetail {
        let response = try await authenticatedNetworkManager.request(
            PlaceTarget.detail(id: id),
            as: ServerResponse<PlaceDetailDTO>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return try mapDetail(data)
    }

    func bookmark(placeID: Int) async throws(NetworkError) {
        try await updateBookmark(PlaceTarget.bookmark(id: placeID))
    }

    func unbookmark(placeID: Int) async throws(NetworkError) {
        try await updateBookmark(PlaceTarget.unbookmark(id: placeID))
    }

    private func updateBookmark(_ target: PlaceTarget) async throws(NetworkError) {
        let response = try await authenticatedNetworkManager.request(
            target,
            as: ServerResponse<EmptyResponse>.self
        )
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }
}

private func mapCoordinate(_ dto: PlaceCoordinateDTO) throws(NetworkError) -> PlaceCoordinate {
    PlaceCoordinate(
        id: dto.id,
        type: try placeType(from: dto.type),
        name: dto.name,
        address: dto.address,
        latitude: dto.lat,
        longitude: dto.lng
    )
}

private func mapListItem(_ dto: PlaceListItemDTO) throws(NetworkError) -> PlaceListItem {
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

private func mapCursorPage(_ dto: PlaceCursorPageDTO) throws(NetworkError) -> PlaceCursorPage {
    var items: [PlaceListItem] = []
    for item in dto.items {
        items.append(try mapListItem(item))
    }
    return PlaceCursorPage(
        items: items,
        hasNext: dto.hasNext,
        nextCursor: dto.nextCursor,
        totalCount: dto.totalCount
    )
}

private func mapDetail(_ dto: PlaceDetailDTO) throws(NetworkError) -> PlaceDetail {
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

private func placeType(from serverValue: String) throws(NetworkError) -> PlaceType {
    guard let value = PlaceType(rawValue: serverValue) else {
        throw .apiError(code: "PLACE_INVALID_TYPE", message: "장소 유형을 확인하지 못했어요.")
    }
    return value
}
