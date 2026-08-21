//
//  PlaceRepositoryImpl.swift
//  Rodi
//

import Foundation

// Place remote DTO를 앱의 장소 계약으로 변환한다.

final class PlaceRepositoryImpl: PlaceRepository {
    private let remoteDataSource: PlaceRemoteDataSource

    init(
        remoteDataSource: PlaceRemoteDataSource
    ) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinate] {
        let data = try await remoteDataSource.fetchCoordinates()
        return try data.map(PlaceMapper.coordinate(from:))
    }

    func fetchPlaces(
        query: PlaceListQuery,
        access: PlaceListAccess
    ) async throws(NetworkError) -> PlaceCursorPage {
        try PlaceMapper.cursorPage(
            from: await remoteDataSource.fetchPlaces(
                query: .init(query),
                access: .init(access)
            )
        )
    }

    func searchPlaces(query: PlaceSearchQuery) async throws(NetworkError) -> PlaceCursorPage {
        try PlaceMapper.cursorPage(
            from: await remoteDataSource.search(.init(query))
        )
    }

    func fetchRelatedSearches(query: PlaceRelatedSearchQuery) async throws(NetworkError) -> PlaceRelatedSearchResult {
        try PlaceMapper.relatedSearchResult(
            from: await remoteDataSource.relatedSearch(.init(query))
        )
    }

    func fetchBookmarkedPlaces(query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPage {
        try PlaceMapper.cursorPage(
            from: await remoteDataSource.bookmarks(.init(query))
        )
    }

    func fetchPlaceDetail(id: Int) async throws(NetworkError) -> PlaceDetail {
        try PlaceMapper.detail(from: await remoteDataSource.detail(id: id))
    }

    func bookmark(placeID: Int) async throws(NetworkError) {
        try await remoteDataSource.bookmark(id: placeID)
    }

    func unbookmark(placeID: Int) async throws(NetworkError) {
        try await remoteDataSource.unbookmark(id: placeID)
    }

}
