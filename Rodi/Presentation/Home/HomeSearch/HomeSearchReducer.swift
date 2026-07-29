//
//  HomeSearchReducer.swift
//  Rodi
//

import Foundation

struct HomeSearchReducer: Reducer {
    enum ViewState: Equatable {
        case initial
        case searching
        case results
        case emptyResults
    }

    struct State {
        var query = ""
        var submittedQuery: String?
        var recentSearches: [RecentSearch] = []
        var administrativeAreas: [KoreanAdministrativeArea] = []
        var results: [PlaceListItem] = []
        var viewState: ViewState = .initial
        var isLoadingRecentSearches = false
        var isLoadingNextPage = false
        var hasNextPage = false
        var nextCursor: String?
        var snackbarMessage: String?
        var selectedPlace: PlaceListItem?
        var selectedAdministrativeArea: KoreanAdministrativeArea?
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case searchSubmitted
        case recentSearchTapped(RecentSearch)
        case loadNextPage
        case searchLoaded(PlaceCursorPage, query: String, isAppending: Bool)
        case searchFailed(NetworkError, query: String, isAppending: Bool)
        case recentSearchesLoaded([RecentSearch])
        case recentSearchesFailed(NetworkError)
        case recentSearchDeleteTapped(Int)
        case recentSearchDeleted(Int)
        case recentSearchDeleteFailed(NetworkError)
        case clearAllRecentSearchesTapped
        case allRecentSearchesDeleted
        case allRecentSearchesDeleteFailed(NetworkError)
        case resultTapped(PlaceListItem)
        case selectionHandled
        case administrativeAreaTapped(KoreanAdministrativeArea)
        case administrativeAreaSelectionHandled
        case dismissSnackbar
    }

    private enum EffectID: Hashable {
        case search
        case recentSearches
        case snackbar
    }

    private let placeRepository: PlaceRepository
    private let recentSearchRepository: RecentSearchRepository
    private let administrativeAreaSearchService: KoreanAdministrativeAreaSearching
    private let origin: RodiCoordinate

    init(
        placeRepository: PlaceRepository,
        recentSearchRepository: RecentSearchRepository,
        administrativeAreaSearchService: KoreanAdministrativeAreaSearching,
        origin: RodiCoordinate
    ) {
        self.placeRepository = placeRepository
        self.recentSearchRepository = recentSearchRepository
        self.administrativeAreaSearchService = administrativeAreaSearchService
        self.origin = origin
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.isLoadingRecentSearches, state.recentSearches.isEmpty else { return .none }
            state.isLoadingRecentSearches = true
            return loadRecentSearchesEffect()

        case .queryChanged(let rawQuery):
            let query = String(rawQuery.prefix(50))
            state.query = query
            state.selectedPlace = nil
            state.selectedAdministrativeArea = nil

            guard normalized(query) == state.submittedQuery else {
                state.results = []
                state.administrativeAreas = []
                state.hasNextPage = false
                state.nextCursor = nil
                state.isLoadingNextPage = false
                state.viewState = .initial
                state.submittedQuery = nil
                return .cancel(id: EffectID.search)
            }
            return .none

        case .searchSubmitted:
            let query = normalized(state.query)
            guard !query.isEmpty else { return .none }
            state.query = query
            state.submittedQuery = query
            state.results = []
            state.administrativeAreas = administrativeAreaSearchService.search(query: query)
            state.hasNextPage = false
            state.nextCursor = nil
            state.viewState = .searching
            return searchEffect(keyword: query, cursor: nil, isAppending: false)

        case .recentSearchTapped(let recentSearch):
            state.query = recentSearch.keyword
            state.submittedQuery = recentSearch.keyword
            state.results = []
            state.administrativeAreas = administrativeAreaSearchService.search(query: recentSearch.keyword)
            state.hasNextPage = false
            state.nextCursor = nil
            state.viewState = .searching
            return searchEffect(keyword: recentSearch.keyword, cursor: nil, isAppending: false)

        case .loadNextPage:
            guard let query = state.submittedQuery,
                  state.hasNextPage,
                  !state.isLoadingNextPage,
                  let cursor = state.nextCursor
            else {
                return .none
            }
            state.isLoadingNextPage = true
            return searchEffect(keyword: query, cursor: cursor, isAppending: true)

        case let .searchLoaded(page, query, isAppending):
            guard state.submittedQuery == normalized(query),
                  normalized(state.query) == normalized(query)
            else {
                return .none
            }
            state.isLoadingNextPage = false
            state.results = isAppending ? state.results + page.items : page.items
            state.hasNextPage = page.hasNext
            state.nextCursor = page.nextCursor
            state.viewState = state.results.isEmpty ? .emptyResults : .results
            guard !isAppending else { return .none }
            state.isLoadingRecentSearches = true
            return loadRecentSearchesEffect()

        case let .searchFailed(error, query, isAppending):
            guard state.submittedQuery == normalized(query),
                  normalized(state.query) == normalized(query)
            else {
                return .none
            }
            state.isLoadingNextPage = false
            if !isAppending, state.results.isEmpty {
                state.viewState = .initial
            }
            return showSnackbar(error.localizedDescription, state: &state)

        case .recentSearchesLoaded(let recentSearches):
            state.isLoadingRecentSearches = false
            state.recentSearches = recentSearches
            return .none

        case .recentSearchesFailed(let error):
            state.isLoadingRecentSearches = false
            return showSnackbar(error.localizedDescription, state: &state)

        case .recentSearchDeleteTapped(let id):
            return deleteRecentSearchEffect(id: id)

        case .recentSearchDeleted(let id):
            state.recentSearches.removeAll { $0.id == id }
            return .none

        case .recentSearchDeleteFailed(let error):
            return showSnackbar(error.localizedDescription, state: &state)

        case .clearAllRecentSearchesTapped:
            guard !state.recentSearches.isEmpty else { return .none }
            return deleteAllRecentSearchesEffect()

        case .allRecentSearchesDeleted:
            state.recentSearches = []
            return .none

        case .allRecentSearchesDeleteFailed(let error):
            return showSnackbar(error.localizedDescription, state: &state)

        case .resultTapped(let place):
            state.selectedPlace = place
            return .none

        case .selectionHandled:
            state.selectedPlace = nil
            return .none

        case .administrativeAreaTapped(let area):
            state.selectedAdministrativeArea = area
            return .none

        case .administrativeAreaSelectionHandled:
            state.selectedAdministrativeArea = nil
            return .none

        case .dismissSnackbar:
            state.snackbarMessage = nil
            return .none
        }
    }

    private func loadRecentSearchesEffect() -> Effect<Action> {
        let repository = recentSearchRepository
        return .run { send in
            do {
                await send(.recentSearchesLoaded(try await repository.fetchRecentSearches()))
            } catch let error as NetworkError {
                await send(.recentSearchesFailed(error))
            } catch {
                await send(.recentSearchesFailed(.unknown(errorCode: error.localizedDescription)))
            }
        }
        .cancelTask(id: EffectID.recentSearches)
    }

    private func searchEffect(
        keyword: String,
        cursor: String?,
        isAppending: Bool
    ) -> Effect<Action> {
        let repository = placeRepository
        let origin = origin
        return .run { send in
            do {
                let page = try await repository.searchPlaces(
                    query: PlaceSearchQuery(
                        keyword: keyword,
                        currentLatitude: origin.latitude,
                        currentLongitude: origin.longitude,
                        cursor: cursor
                    )
                )
                await send(.searchLoaded(page, query: keyword, isAppending: isAppending))
            } catch let error as NetworkError {
                await send(.searchFailed(error, query: keyword, isAppending: isAppending))
            } catch {
                await send(.searchFailed(.unknown(errorCode: error.localizedDescription), query: keyword, isAppending: isAppending))
            }
        }
        .cancelTask(id: EffectID.search)
    }

    private func deleteRecentSearchEffect(id: Int) -> Effect<Action> {
        let repository = recentSearchRepository
        return .run { send in
            do {
                try await repository.deleteRecentSearch(id: id)
                await send(.recentSearchDeleted(id))
            } catch let error as NetworkError {
                await send(.recentSearchDeleteFailed(error))
            } catch {
                await send(.recentSearchDeleteFailed(.unknown(errorCode: error.localizedDescription)))
            }
        }
    }

    private func deleteAllRecentSearchesEffect() -> Effect<Action> {
        let repository = recentSearchRepository
        return .run { send in
            do {
                try await repository.deleteAllRecentSearches()
                await send(.allRecentSearchesDeleted)
            } catch let error as NetworkError {
                await send(.allRecentSearchesDeleteFailed(error))
            } catch {
                await send(.allRecentSearchesDeleteFailed(.unknown(errorCode: error.localizedDescription)))
            }
        }
    }

    private func showSnackbar(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await send(.dismissSnackbar)
        }
        .cancelTask(id: EffectID.snackbar)
    }

    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
