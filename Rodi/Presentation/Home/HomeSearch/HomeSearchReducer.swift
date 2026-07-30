//
//  HomeSearchReducer.swift
//  Rodi
//

import Foundation

struct HomeSearchReducer: Reducer {
    enum SearchContext: Equatable {
        case regular
        case administrativeArea(KoreanAdministrativeArea)
    }

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
        var selectedAdministrativeAreaSearch: AdministrativeAreaSearchResult?
        var searchRequestID = 0
        var activeSearchContext: SearchContext?
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case searchSubmitted
        case recentSearchTapped(RecentSearch)
        case loadNextPage
        case searchLoaded(PlaceCursorPage, requestID: Int, isAppending: Bool)
        case searchFailed(NetworkError, requestID: Int, isAppending: Bool)
        case administrativeAreaSearchLoaded(KoreanAdministrativeArea, [PlaceListItem], requestID: Int)
        case administrativeAreaSearchFailed(NetworkError, requestID: Int)
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
        case administrativeAreaSearchSelectionHandled
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
            state.selectedAdministrativeAreaSearch = nil

            guard normalized(query) == state.submittedQuery else {
                state.searchRequestID += 1
                state.activeSearchContext = nil
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
            state.searchRequestID += 1
            state.activeSearchContext = .regular
            state.results = []
            state.administrativeAreas = administrativeAreaSearchService.search(query: query)
            state.hasNextPage = false
            state.nextCursor = nil
            state.viewState = .searching
            return searchEffect(keyword: query, cursor: nil, requestID: state.searchRequestID, isAppending: false)

        case .recentSearchTapped(let recentSearch):
            state.query = recentSearch.keyword
            state.submittedQuery = recentSearch.keyword
            state.searchRequestID += 1
            state.activeSearchContext = .regular
            state.results = []
            state.administrativeAreas = administrativeAreaSearchService.search(query: recentSearch.keyword)
            state.hasNextPage = false
            state.nextCursor = nil
            state.viewState = .searching
            return searchEffect(
                keyword: recentSearch.keyword,
                cursor: nil,
                requestID: state.searchRequestID,
                isAppending: false
            )

        case .loadNextPage:
            guard let query = state.submittedQuery,
                  state.activeSearchContext == .regular,
                  state.hasNextPage,
                  !state.isLoadingNextPage,
                  let cursor = state.nextCursor
            else {
                return .none
            }
            state.isLoadingNextPage = true
            return searchEffect(
                keyword: query,
                cursor: cursor,
                requestID: state.searchRequestID,
                isAppending: true
            )

        case let .searchLoaded(page, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  state.activeSearchContext == .regular
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

        case let .searchFailed(error, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  state.activeSearchContext == .regular
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
            let keyword = area.searchDisplayName
            state.query = keyword
            state.submittedQuery = keyword
            state.searchRequestID += 1
            state.activeSearchContext = .administrativeArea(area)
            state.administrativeAreas = []
            state.results = []
            state.hasNextPage = false
            state.nextCursor = nil
            state.isLoadingNextPage = false
            state.viewState = .searching
            return administrativeAreaSearchEffect(area: area, requestID: state.searchRequestID)

        case let .administrativeAreaSearchLoaded(area, items, requestID):
            guard requestID == state.searchRequestID,
                  state.activeSearchContext == .administrativeArea(area)
            else {
                return .none
            }
            state.isLoadingNextPage = false
            guard !items.isEmpty else {
                state.viewState = .emptyResults
                return .none
            }
            state.viewState = .results
            state.selectedAdministrativeAreaSearch = AdministrativeAreaSearchResult(area: area, items: items)
            return .none

        case let .administrativeAreaSearchFailed(error, requestID):
            guard requestID == state.searchRequestID,
                  case .administrativeArea = state.activeSearchContext
            else {
                return .none
            }
            state.viewState = .initial
            return showSnackbar(error.localizedDescription, state: &state)

        case .administrativeAreaSearchSelectionHandled:
            state.selectedAdministrativeAreaSearch = nil
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
        requestID: Int,
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
                await send(.searchLoaded(page, requestID: requestID, isAppending: isAppending))
            } catch let error as NetworkError {
                await send(.searchFailed(error, requestID: requestID, isAppending: isAppending))
            } catch {
                await send(.searchFailed(.unknown(errorCode: error.localizedDescription), requestID: requestID, isAppending: isAppending))
            }
        }
        .cancelTask(id: EffectID.search)
    }

    private func administrativeAreaSearchEffect(
        area: KoreanAdministrativeArea,
        requestID: Int
    ) -> Effect<Action> {
        let repository = placeRepository
        let origin = origin
        return .run { send in
            do {
                var cursor: String?
                var allItems: [PlaceListItem] = []
                var hasNext = true

                while hasNext {
                    let page = try await repository.searchPlaces(
                        query: PlaceSearchQuery(
                            keyword: area.searchDisplayName,
                            currentLatitude: origin.latitude,
                            currentLongitude: origin.longitude,
                            cursor: cursor
                        )
                    )
                    let existingIDs = Set(allItems.map(\.id))
                    allItems += page.items.filter { !existingIDs.contains($0.id) }
                    hasNext = page.hasNext
                    cursor = page.nextCursor
                    if hasNext, cursor == nil { break }
                }
                await send(.administrativeAreaSearchLoaded(area, allItems, requestID: requestID))
            } catch let error as NetworkError {
                await send(.administrativeAreaSearchFailed(error, requestID: requestID))
            } catch {
                await send(.administrativeAreaSearchFailed(.unknown(errorCode: error.localizedDescription), requestID: requestID))
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
