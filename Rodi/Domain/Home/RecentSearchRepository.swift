//
//  RecentSearchRepository.swift
//  Rodi
//

import Foundation

protocol RecentSearchRepository {
    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch]
    func registerRecentSearch(_ registration: RecentSearchRegistration) async throws(NetworkError)
    func deleteRecentSearch(id: Int) async throws(NetworkError)
    func deleteAllRecentSearches() async throws(NetworkError)
}
