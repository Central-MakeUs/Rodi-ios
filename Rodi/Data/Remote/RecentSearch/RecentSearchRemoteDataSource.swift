import Foundation

final class RecentSearchRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetch() async throws(NetworkError) -> [RecentSearchDTO] {
        let response = try await networkManager.request(RecentSearchAPI.list, as: ServerResponse<[RecentSearchDTO]>.self)
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data
    }

    func register(_ request: RecentSearchRegisterRequestDTO) async throws(NetworkError) {
        try await perform(RecentSearchAPI.register(request))
    }

    func delete(id: Int) async throws(NetworkError) {
        try await perform(.delete(id: id))
    }

    func deleteAll() async throws(NetworkError) {
        try await perform(.deleteAll)
    }

    private func perform(_ api: RecentSearchAPI) async throws(NetworkError) {
        let response = try await networkManager.request(api, as: ServerResponse<EmptyResponse>.self)
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }
}
