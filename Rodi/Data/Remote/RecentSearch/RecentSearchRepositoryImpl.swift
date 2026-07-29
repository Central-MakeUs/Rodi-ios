//
//  RecentSearchRepositoryImpl.swift
//  Rodi
//

import Foundation

final class RecentSearchRepositoryImpl: RecentSearchRepository {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch] {
        let response = try await networkManager.request(
            RecentSearchTarget.list,
            as: ServerResponse<[RecentSearchDTO]>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data.map { RecentSearch(id: $0.id, keyword: $0.keyword) }
    }

    func deleteRecentSearch(id: Int) async throws(NetworkError) {
        try await delete(RecentSearchTarget.delete(id: id))
    }

    func deleteAllRecentSearches() async throws(NetworkError) {
        try await delete(RecentSearchTarget.deleteAll)
    }

    private func delete(_ target: RecentSearchTarget) async throws(NetworkError) {
        let response = try await networkManager.request(target, as: ServerResponse<EmptyResponse>.self)
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }
}
