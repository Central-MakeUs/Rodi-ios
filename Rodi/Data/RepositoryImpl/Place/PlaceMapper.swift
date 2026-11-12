//
//  PlaceMapper.swift
//  Rodi
//

import Foundation

nonisolated struct PlaceMapper {
    static func clusterQuery(from query: PlaceClusterQuery) -> PlaceClusterQueryDTO {
        let viewport = query.viewport
        return .init(
            swLat: viewport.southWestLatitude, swLng: viewport.southWestLongitude,
            neLat: viewport.northEastLatitude, neLng: viewport.northEastLongitude,
            practiceTypes: query.practiceTypes.isEmpty ? nil : query.practiceTypes.map(\.rawValue)
        )
    }

    static func clusterResult(from dto: PlaceClusterResponseDTO) throws(NetworkError) -> PlaceClusterResult {
        let places = try dto.places.map(coordinate(from:))
        let placeIDs = Set(places.map(\.id))
        guard placeIDs.count == places.count, !dto.levels.isEmpty,
              places.allSatisfy({ (-90...90).contains($0.latitude) && (-180...180).contains($0.longitude) })
        else { throw .decodingFail }

        var levels: [PlaceClusterLevel] = []
        for level in dto.levels {
            guard level.minLngSpan.isFinite, level.minLngSpan >= 0,
                  level.maxLngSpan.map({ $0.isFinite && $0 > level.minLngSpan }) ?? true
            else { throw .decodingFail }
            let ids = try level.placeIds.map(int(from:))
            guard Set(ids).count == ids.count, Set(ids).isSubset(of: placeIDs) else { throw .decodingFail }

            var clusters: [PlaceCluster] = []
            for cluster in level.clusters {
                let bounds = cluster.bounds
                guard (-90...90).contains(cluster.lat), (-180...180).contains(cluster.lng),
                      cluster.count > 0,
                      (-90...90).contains(bounds.swLat), (-90...90).contains(bounds.neLat),
                      (-180...180).contains(bounds.swLng), (-180...180).contains(bounds.neLng),
                      bounds.swLat <= bounds.neLat, bounds.swLng <= bounds.neLng
                else { throw .decodingFail }
                clusters.append(.init(
                    latitude: cluster.lat, longitude: cluster.lng, count: cluster.count,
                    bounds: .init(southWestLatitude: bounds.swLat, southWestLongitude: bounds.swLng,
                                  northEastLatitude: bounds.neLat, northEastLongitude: bounds.neLng)
                ))
            }
            levels.append(.init(minLongitudeSpan: level.minLngSpan, maxLongitudeSpan: level.maxLngSpan,
                                clusters: clusters, placeIDs: ids))
        }
        levels.sort { $0.minLongitudeSpan < $1.minLongitudeSpan }
        guard levels.first?.minLongitudeSpan == 0, levels.last?.maxLongitudeSpan == nil,
              zip(levels, levels.dropFirst()).allSatisfy({ $0.maxLongitudeSpan == $1.minLongitudeSpan })
        else { throw .decodingFail }
        return .init(places: places, levels: levels)
    }

    static func listQuery(from query: PlaceListQuery) -> PlaceListQueryDTO {
        .init(
            southWestLatitude: query.viewport.southWestLatitude,
            southWestLongitude: query.viewport.southWestLongitude,
            northEastLatitude: query.viewport.northEastLatitude,
            northEastLongitude: query.viewport.northEastLongitude,
            currentLatitude: query.currentLatitude,
            currentLongitude: query.currentLongitude,
            size: query.size,
            cursor: query.cursor,
            practiceTypes: query.practiceTypes.map(\.rawValue)
        )
    }

    static func searchQuery(from query: PlaceSearchQuery) -> PlaceSearchQueryDTO {
        .init(
            keyword: query.keyword,
            currentLatitude: query.currentLatitude,
            currentLongitude: query.currentLongitude,
            size: query.size,
            cursor: query.cursor,
            practiceTypes: query.practiceTypes.map(\.rawValue)
        )
    }

    static func relatedSearchQuery(
        from query: PlaceRelatedSearchQuery
    ) -> PlaceRelatedSearchQueryDTO {
        .init(keyword: query.keyword, size: query.size, cursor: query.cursor)
    }

    static func bookmarkListQuery(
        from query: PlaceBookmarkListQuery
    ) -> PlaceBookmarkListQueryDTO {
        .init(size: query.size, cursor: query.cursor)
    }

    static func coordinate(
        from dto: PlaceCoordinateDTO
    ) throws(NetworkError) -> PlaceCoordinate {
        PlaceCoordinate(
            id: try int(from: dto.id),
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
            items: try dto.items
                .map(listItem(from:))
                .filter { !$0.isDeleted },
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
            places: PlaceRelatedSearchCursorPage(
                items: try dto.places.items.map(relatedSearchSuggestion(from:)),
                hasNext: dto.places.hasNext,
                nextCursor: dto.places.nextCursor,
                totalCount: dto.places.totalCount
            )
        )
    }

    static func detail(
        from dto: PlaceDetailDTO
    ) throws(NetworkError) -> PlaceDetail {
        PlaceDetail(
            id: try int(from: dto.id),
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

nonisolated extension PlaceListQueryDTO {
    init(_ query: PlaceListQuery) {
        self = PlaceMapper.listQuery(from: query)
    }
}

nonisolated extension PlaceSearchQueryDTO {
    init(_ query: PlaceSearchQuery) {
        self = PlaceMapper.searchQuery(from: query)
    }
}

nonisolated extension PlaceRelatedSearchQueryDTO {
    init(_ query: PlaceRelatedSearchQuery) {
        self = PlaceMapper.relatedSearchQuery(from: query)
    }
}

nonisolated extension PlaceBookmarkListQueryDTO {
    init(_ query: PlaceBookmarkListQuery) {
        self = PlaceMapper.bookmarkListQuery(from: query)
    }
}

nonisolated extension PlaceRemoteAccess {
    init(_ access: PlaceListAccess) {
        switch access {
        case .public:
            self = .public
        case .member:
            self = .authenticated
        }
    }
}

nonisolated private extension PlaceMapper {
    static func relatedSearchSuggestion(
        from dto: PlaceRelatedSearchItemDTO
    ) throws(NetworkError) -> PlaceRelatedSearchSuggestion {
        PlaceRelatedSearchSuggestion(
            id: try int(from: dto.placeID),
            name: dto.name,
            region: dto.region
        )
    }

    static func listItem(
        from dto: PlaceListItemDTO
    ) throws(NetworkError) -> PlaceListItem {
        PlaceListItem(
            id: try int(from: dto.id),
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
            openTime: dto.openTime,
            isDeleted: dto.isDeleted ?? false
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

    static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }
}

nonisolated private extension PlaceCourseDetailDTO {
    var domain: PlaceCourseDetail {
        PlaceCourseDetail(
            summary: description,
            cautions: cautions ?? [],
            distanceMeters: distanceMeters,
            waypoints: (waypoints ?? []).map(\.domain)
        )
    }
}

nonisolated private extension PlaceWaypointDTO {
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

nonisolated private extension PlaceParkingDetailDTO {
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

nonisolated private extension PlaceFeeInfoDTO {
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

nonisolated private extension PlaceOperatingHoursDTO {
    var domain: PlaceOperatingHours {
        PlaceOperatingHours(
            weekday: weekday,
            saturday: saturday,
            holiday: holiday
        )
    }
}
