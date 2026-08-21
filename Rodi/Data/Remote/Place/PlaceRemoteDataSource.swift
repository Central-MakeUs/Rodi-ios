import Foundation

final class PlaceRemoteDataSource {
    private let publicNetworkManager: NetworkManager
    private let authenticatedNetworkManager: NetworkManager

    init(publicNetworkManager: NetworkManager, authenticatedNetworkManager: NetworkManager) {
        self.publicNetworkManager = publicNetworkManager
        self.authenticatedNetworkManager = authenticatedNetworkManager
    }

    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinateDTO] {
        try await ServerResponseHandler.payload(
            PlaceAPI.coordinates,
            using: publicNetworkManager,
            as: [PlaceCoordinateDTO].self
        )
    }

    func fetchPlaces(
        query: PlaceListQueryDTO,
        access: PlaceRemoteAccess
    ) async throws(NetworkError) -> PlaceCursorPageDTO {
        switch access {
        case .public:
            try await ServerResponseHandler.payload(
                PlaceAPI.list(query),
                using: publicNetworkManager,
                as: PlaceCursorPageDTO.self
            )
        case .authenticated:
            try await ServerResponseHandler.payload(
                PlaceAPI.authenticatedList(query),
                using: authenticatedNetworkManager,
                as: PlaceCursorPageDTO.self
            )
        }
    }

    func search(_ query: PlaceSearchQueryDTO) async throws(NetworkError) -> PlaceCursorPageDTO {
        try await ServerResponseHandler.payload(
            PlaceAPI.search(query),
            using: authenticatedNetworkManager,
            as: PlaceCursorPageDTO.self
        )
    }

    func relatedSearch(_ query: PlaceRelatedSearchQueryDTO) async throws(NetworkError) -> PlaceRelatedSearchDTO {
        try await ServerResponseHandler.payload(
            PlaceAPI.relatedSearch(query),
            using: authenticatedNetworkManager,
            as: PlaceRelatedSearchDTO.self
        )
    }

    func bookmarks(_ query: PlaceBookmarkListQueryDTO) async throws(NetworkError) -> PlaceCursorPageDTO {
        try await ServerResponseHandler.payload(
            PlaceAPI.bookmarks(query),
            using: authenticatedNetworkManager,
            as: PlaceCursorPageDTO.self
        )
    }

    func detail(id: Int) async throws(NetworkError) -> PlaceDetailDTO {
        try await ServerResponseHandler.payload(
            PlaceAPI.detail(id: id),
            using: authenticatedNetworkManager,
            as: PlaceDetailDTO.self
        )
    }

    func bookmark(id: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(PlaceAPI.bookmark(id: id), using: authenticatedNetworkManager)
    }

    func unbookmark(id: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(PlaceAPI.unbookmark(id: id), using: authenticatedNetworkManager)
    }
}

enum PlaceRemoteAccess {
    case `public`
    case authenticated
}
