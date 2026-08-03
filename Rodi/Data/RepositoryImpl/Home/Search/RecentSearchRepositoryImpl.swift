//
//  RecentSearchRepositoryImpl.swift
//  Rodi
//

import Foundation

// Search remote DTO를 앱의 검색 계약으로 변환한다.

final class RecentSearchRepositoryImpl: RecentSearchRepository {
    private let remoteDataSource: RecentSearchRemoteDataSource

    init(remoteDataSource: RecentSearchRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch] {
        let data = try await remoteDataSource.fetch()
        return try data.map(RecentSearchMapper.search(from:))
    }

    func registerRecentSearch(_ registration: RecentSearchRegistration) async throws(NetworkError) {
        try await remoteDataSource.register(RecentSearchRegisterRequestDTO(type: registration.kind.rawValue, keyword: registration.keyword, placeId: registration.placeID))
    }

    func deleteRecentSearch(id: Int) async throws(NetworkError) {
        try await remoteDataSource.delete(id: id)
    }

    func deleteAllRecentSearches() async throws(NetworkError) {
        try await remoteDataSource.deleteAll()
    }

}
