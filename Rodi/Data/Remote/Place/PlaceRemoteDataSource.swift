import Foundation

final class PlaceRemoteDataSource {
    private let publicNetworkManager: NetworkManager
    private let authenticatedNetworkManager: NetworkManager

    init(publicNetworkManager: NetworkManager, authenticatedNetworkManager: NetworkManager) {
        self.publicNetworkManager = publicNetworkManager
        self.authenticatedNetworkManager = authenticatedNetworkManager
    }

    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinateDTO] {
        try await request(.coordinates, manager: publicNetworkManager, as: [PlaceCoordinateDTO].self)
    }

    func fetchPlaces(query: PlaceListQuery, access: PlaceListAccess) async throws(NetworkError) -> PlaceCursorPageDTO {
        switch access {
        case .public: try await request(.list(query), manager: publicNetworkManager, as: PlaceCursorPageDTO.self)
        case .member: try await request(.authenticatedList(query), manager: authenticatedNetworkManager, as: PlaceCursorPageDTO.self)
        }
    }

    func search(_ query: PlaceSearchQuery) async throws(NetworkError) -> PlaceCursorPageDTO {
        try await request(.search(query), manager: authenticatedNetworkManager, as: PlaceCursorPageDTO.self)
    }

    func relatedSearch(_ query: PlaceRelatedSearchQuery) async throws(NetworkError) -> PlaceRelatedSearchDTO {
        try await request(.relatedSearch(query), manager: authenticatedNetworkManager, as: PlaceRelatedSearchDTO.self)
    }

    func bookmarks(_ query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPageDTO {
        try await request(.bookmarks(query), manager: authenticatedNetworkManager, as: PlaceCursorPageDTO.self)
    }

    func detail(id: Int) async throws(NetworkError) -> PlaceDetailDTO {
        try await request(.detail(id: id), manager: authenticatedNetworkManager, as: PlaceDetailDTO.self)
    }

    func bookmark(id: Int) async throws(NetworkError) {
        try await empty(.bookmark(id: id))
    }

    func unbookmark(id: Int) async throws(NetworkError) {
        try await empty(.unbookmark(id: id))
    }

    private func empty(_ api: PlaceAPI) async throws(NetworkError) {
        _ = try await request(api, manager: authenticatedNetworkManager, as: EmptyResponse.self)
    }

    private func request<T: Decodable>(
        _ api: PlaceAPI,
        manager: NetworkManager,
        as type: T.Type
    ) async throws(NetworkError) -> T {
        let response = try await manager.request(api, as: ServerResponse<T>.self)
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data
    }
}
