//
//  RecentSearchRepository.swift
//  Rodi
//

import Foundation

struct RecentSearch: Equatable, Identifiable {
    let id: Int
    let keyword: String
}

protocol RecentSearchRepository {
    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch]
    func deleteRecentSearch(id: Int) async throws(NetworkError)
    func deleteAllRecentSearches() async throws(NetworkError)
}
