import XCTest
@testable import Rodi

@MainActor
final class HomeSearchReducerTests: XCTestCase {
    func testPreviousSuggestionResponseDoesNotReplaceNewQuery() {
        let reducer = HomeSearchReducer(
            placeRepository: PlaceRepositoryStub(),
            recentSearchRepository: RecentSearchRepositoryStub()
        )
        var state = HomeSearchState()

        _ = reducer.reduce(&state, with: .queryChanged("서울"))
        let previousRequestID = state.results.requestID

        _ = reducer.reduce(&state, with: .queryChanged("부산"))

        _ = reducer.reduce(
            &state,
            with: .relatedSearchLoaded(
                .init(
                    regions: ["서울특별시"],
                    places: .init(items: [.init(id: 1, name: "이전 장소", region: "서울")], hasNext: false, nextCursor: nil, totalCount: 1)
                ),
                requestID: previousRequestID,
                isAppending: false
            )
        )

        XCTAssertEqual(state.query, "부산")
        XCTAssertEqual(state.results.activeContext, .suggestions(keyword: "부산"))
        XCTAssertTrue(state.results.regions.isEmpty)
        XCTAssertTrue(state.results.relatedPlaceSuggestions.isEmpty)
        XCTAssertEqual(state.results.viewState, .searching)
    }
}

private struct PlaceRepositoryStub: PlaceRepository {
    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinate] { [] }
    func fetchPlaces(query: PlaceListQuery, access: PlaceListAccess) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func searchPlaces(query: PlaceSearchQuery) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func fetchRelatedSearches(query: PlaceRelatedSearchQuery) async throws(NetworkError) -> PlaceRelatedSearchResult { .init(regions: [], places: .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0)) }
    func fetchBookmarkedPlaces(query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func fetchPlaceDetail(id: Int) async throws(NetworkError) -> PlaceDetail { fatalError() }
    func bookmark(placeID: Int) async throws(NetworkError) {}
    func unbookmark(placeID: Int) async throws(NetworkError) {}
}

private struct RecentSearchRepositoryStub: RecentSearchRepository {
    func fetchRecentSearches() async throws(NetworkError) -> [RecentSearch] { [] }
    func registerRecentSearch(_ registration: RecentSearchRegistration) async throws(NetworkError) {}
    func deleteRecentSearch(id: Int) async throws(NetworkError) {}
    func deleteAllRecentSearches() async throws(NetworkError) {}
}
