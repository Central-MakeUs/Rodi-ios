import Foundation

final class RecentSearchRepositoryImpl: RecentSearchRepository {
    private let remoteDataSource: RecentSearchRemoteDataSource

    init(remoteDataSource: RecentSearchRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch] {
        let dto = try await remoteDataSource.fetch()
        return try dto.map(RecentSearchMapper.search(from:))
    }

    func registerRecentSearch(
        _ registration: RecentSearchRegistration
    ) async throws(NetworkError) {
        try await remoteDataSource.register(.init(registration))
    }

    func deleteRecentSearch(id: Int) async throws(NetworkError) {
        try await remoteDataSource.delete(id: id)
    }

    func deleteAllRecentSearches() async throws(NetworkError) {
        try await remoteDataSource.deleteAll()
    }
}
