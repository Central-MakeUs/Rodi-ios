import Foundation

final class RecentSearchRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetch() async throws(NetworkError) -> [RecentSearchDTO] {
        try await ServerResponseHandler.payload(
            RecentSearchAPI.list,
            using: networkManager,
            as: [RecentSearchDTO].self
        )
    }

    func register(_ request: RecentSearchRegisterRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(
            RecentSearchAPI.register(request),
            using: networkManager
        )
    }

    func delete(id: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(RecentSearchAPI.delete(id: id), using: networkManager)
    }

    func deleteAll() async throws(NetworkError) {
        try await ServerResponseHandler.empty(RecentSearchAPI.deleteAll, using: networkManager)
    }
}
