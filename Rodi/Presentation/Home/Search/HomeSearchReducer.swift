//
//  HomeSearchReducer.swift
//  Rodi
//

import Foundation

struct HomeSearchReducer: Reducer {
    typealias State = HomeSearchState

    enum Action {
        case appeared(origin: RodiCoordinate)
        case queryChanged(String)
        case searchSubmitted
        case recentSearchTapped(RecentSearch)
        case regionTapped(String)
        case loadNextPage
        case relatedSearchLoaded(PlaceRelatedSearchResult, requestID: Int, isAppending: Bool)
        case relatedSearchFailed(NetworkError, requestID: Int, isAppending: Bool)
        case searchLoaded(PlaceCursorPage, requestID: Int, isAppending: Bool)
        case searchFailed(NetworkError, requestID: Int, isAppending: Bool)
        case recentSearchesLoaded([RecentSearch])
        case recentSearchesFailed(NetworkError)
        case recentSearchDeleteTapped(Int)
        case recentSearchDeleted(Int)
        case recentSearchDeleteFailed(NetworkError)
        case clearAllRecentSearchesTapped
        case allRecentSearchesDeleted
        case allRecentSearchesDeleteFailed(NetworkError)
        case resultTapped(PlaceListItem)
        case relatedPlaceSuggestionTapped(PlaceRelatedSearchSuggestion)
        case dismissTapped
        case delegate(Delegate)
    }

    enum Delegate {
        case placeSelected(id: Int, name: String)
        case regionSelected(name: String, center: RodiCoordinate)
        case dismissed
        case showSnackbar(String)
    }

    private enum EffectID: Hashable {
        case search
        case recentSearches
    }

    private let placeRepository: PlaceRepository
    private let recentSearchRepository: RecentSearchRepository
    init(
        placeRepository: PlaceRepository,
        recentSearchRepository: RecentSearchRepository
    ) {
        self.placeRepository = placeRepository
        self.recentSearchRepository = recentSearchRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared(let origin):
            state.origin = origin
            if !state.hasTrackedSearchOpen {
                state.hasTrackedSearchOpen = true
                RodiAnalytics.track(.searchOpened)
            }
            guard !state.recent.isLoading, state.recent.searches.isEmpty else { return .none }
            state.recent.isLoading = true
            return loadRecentSearchesEffect()

        case .queryChanged(let rawQuery):
            let query = String(rawQuery.prefix(50))
            state.query = query
            state.results.loadedSuggestionKeyword = nil

            guard !normalized(query).isEmpty else {
                resetSearch(state: &state)
                return .cancel(id: EffectID.search)
            }
            return beginSuggestionSearch(
                keyword: normalized(query),
                delay: true,
                state: &state
            )

        case .searchSubmitted:
            let query = normalized(state.query)
            guard !query.isEmpty else { return .none }
            RodiAnalytics.track(
                .searchSubmitted(
                    inputSource: "keyboard",
                    queryLengthBucket: RodiAnalytics.lengthBucket(for: query)
                )
            )
            state.query = query
            guard state.results.loadedSuggestionKeyword != query else { return .none }
            return beginSuggestionSearch(keyword: query, delay: false, state: &state)

        case .recentSearchTapped(let recentSearch):
            RodiAnalytics.track(
                .searchSubmitted(
                    inputSource: "recent_search",
                    queryLengthBucket: RodiAnalytics.lengthBucket(for: recentSearch.keyword)
                )
            )
            state.query = recentSearch.keyword
            switch recentSearch.kind {
            case .region:
                return selectRegion(
                    named: recentSearch.keyword,
                    state: &state
                )

            case .place:
                guard let placeID = recentSearch.placeID else {
                    return showSnackbar("장소 정보를 불러오지 못했어요.")
                }
                return selectPlaceEffect(
                    id: placeID,
                    name: recentSearch.keyword,
                    registration: .init(
                        kind: .place,
                        keyword: recentSearch.keyword,
                        placeID: placeID
                    )
                )
            }

        case .regionTapped(let region):
            state.query = region
            return selectRegion(named: region, state: &state)

        case .loadNextPage:
            guard state.results.hasNextPage,
                  !state.results.isLoadingNextPage,
                  let cursor = state.results.nextCursor
            else {
                return .none
            }
            state.results.isLoadingNextPage = true
            switch state.results.activeContext {
            case .suggestions(let keyword):
                return relatedSearchEffect(
                    keyword: keyword,
                    cursor: cursor,
                    requestID: state.results.requestID,
                    isAppending: true,
                    delay: false
                )
            case .selectedRegion(let keyword):
                return placeSearchEffect(
                    keyword: keyword,
                    cursor: cursor,
                    requestID: state.results.requestID,
                    isAppending: true,
                    registration: nil,
                    origin: state.origin
                )
            case nil:
                return .none
            }

        case let .relatedSearchLoaded(result, requestID, isAppending):
            guard requestID == state.results.requestID,
                  case .suggestions = state.results.activeContext
            else {
                return .none
            }
            state.results.isLoadingNextPage = false
            state.results.loadedSuggestionKeyword = normalized(state.query)
            state.results.regions = isAppending ? uniqueRegions(state.results.regions + result.regions) : result.regions
            state.results.relatedPlaceSuggestions = isAppending
                ? uniqueSuggestions(state.results.relatedPlaceSuggestions + result.places.items)
                : result.places.items
            state.results.hasNextPage = result.places.hasNext
            state.results.nextCursor = result.places.nextCursor
            state.results.viewState = state.results.regions.isEmpty && state.results.relatedPlaceSuggestions.isEmpty ? .emptyResults : .results
            guard !isAppending else { return .none }
            RodiAnalytics.track(
                .searchResultsLoaded(
                    resultCountBucket: RodiAnalytics.countBucket(for: result.places.items.count),
                    hasRegionCandidates: !result.regions.isEmpty
                )
            )
            return .none

        case let .relatedSearchFailed(error, requestID, isAppending):
            guard requestID == state.results.requestID,
                  case .suggestions = state.results.activeContext
            else {
                return .none
            }
            state.results.isLoadingNextPage = false
            if !isAppending, state.results.relatedPlaceSuggestions.isEmpty, state.results.regions.isEmpty {
                state.results.viewState = .emptyResults
            }
            return showSnackbar(error.localizedDescription)

        case let .searchLoaded(page, requestID, isAppending):
            guard requestID == state.results.requestID,
                  case .selectedRegion = state.results.activeContext
            else {
                return .none
            }
            state.results.isLoadingNextPage = false
            state.results.places = isAppending ? uniqueItems(state.results.places + page.items) : page.items
            state.results.hasNextPage = page.hasNext
            state.results.nextCursor = page.nextCursor
            state.results.viewState = state.results.places.isEmpty ? .emptyResults : .results
            return .none

        case let .searchFailed(error, requestID, isAppending):
            guard requestID == state.results.requestID,
                  case .selectedRegion = state.results.activeContext
            else {
                return .none
            }
            state.results.isLoadingNextPage = false
            if !isAppending, state.results.places.isEmpty {
                state.results.viewState = .emptyResults
            }
            return showSnackbar(error.localizedDescription)

        case .recentSearchesLoaded(let recentSearches):
            state.recent.isLoading = false
            state.recent.searches = recentSearches
            return .none

        case .recentSearchesFailed(let error):
            state.recent.isLoading = false
            return showSnackbar(error.localizedDescription)

        case .recentSearchDeleteTapped(let id):
            return deleteRecentSearchEffect(id: id)

        case .recentSearchDeleted(let id):
            state.recent.searches.removeAll { $0.id == id }
            return .none

        case .recentSearchDeleteFailed(let error):
            return showSnackbar(error.localizedDescription)

        case .clearAllRecentSearchesTapped:
            guard !state.recent.searches.isEmpty else { return .none }
            return deleteAllRecentSearchesEffect()

        case .allRecentSearchesDeleted:
            state.recent.searches = []
            return .none

        case .allRecentSearchesDeleteFailed(let error):
            return showSnackbar(error.localizedDescription)

        case .resultTapped(let place):
            RodiAnalytics.track(.searchResultSelected(resultType: place.type.rawValue, source: "search_results"))
            return selectPlaceEffect(
                id: place.id,
                name: place.name,
                registration: .init(kind: .place, keyword: place.name, placeID: place.id)
            )

        case .relatedPlaceSuggestionTapped(let suggestion):
            RodiAnalytics.track(.searchResultSelected(resultType: "RELATED_SUGGESTION", source: "search_suggestions"))
            return selectPlaceEffect(
                id: suggestion.id,
                name: suggestion.name,
                registration: .init(kind: .place, keyword: suggestion.name, placeID: suggestion.id)
            )

        case .dismissTapped:
            return .send(.delegate(.dismissed))

        case .delegate:
            return .none
        }
    }

    private func beginSuggestionSearch(
        keyword: String,
        delay: Bool,
        state: inout State
    ) -> Effect<Action> {
        state.results.requestID += 1
        state.results.activeContext = .suggestions(keyword: keyword)
        state.results.regions = []
        state.results.relatedPlaceSuggestions = []
        state.results.places = []
        state.results.hasNextPage = false
        state.results.nextCursor = nil
        state.results.isLoadingNextPage = false
        state.results.viewState = .searching
        return relatedSearchEffect(
            keyword: keyword,
            cursor: nil,
            requestID: state.results.requestID,
            isAppending: false,
            delay: delay
        )
    }

    private func beginPlaceSearch(
        keyword: String,
        state: inout State,
        registration: RecentSearchRegistration? = nil
    ) -> Effect<Action> {
        state.results.requestID += 1
        state.results.activeContext = .selectedRegion(keyword: keyword)
        state.results.loadedSuggestionKeyword = nil
        state.results.regions = []
        state.results.relatedPlaceSuggestions = []
        state.results.places = []
        state.results.hasNextPage = false
        state.results.nextCursor = nil
        state.results.isLoadingNextPage = false
        state.results.viewState = .searching
        return placeSearchEffect(
            keyword: keyword,
            cursor: nil,
            requestID: state.results.requestID,
            isAppending: false,
            registration: registration,
            origin: state.origin
        )
    }

    private func selectRegion(
        named region: String,
        state: inout State
    ) -> Effect<Action> {
        guard let center = HomeSearchRegionCenter.coordinate(for: region) else {
            showRegionEmptyState(named: region, state: &state)
            return .cancel(id: EffectID.search)
        }

        resetSearch(state: &state)
        let recentSearchRepository = recentSearchRepository
        return .run { send in
            await send(.delegate(.regionSelected(name: region, center: center)))

            do {
                try await recentSearchRepository.registerRecentSearch(
                    .init(kind: .region, keyword: region)
                )
            } catch {
                RodiLogger.warning(
                    "Recent region search registration failed. error=\(error.localizedDescription)"
                )
            }
        }
        .cancelTask(id: EffectID.search)
    }

    private func showRegionEmptyState(
        named region: String,
        state: inout State
    ) {
        state.results.requestID += 1
        state.results.activeContext = .selectedRegion(keyword: region)
        state.results.loadedSuggestionKeyword = nil
        state.results.regions = []
        state.results.relatedPlaceSuggestions = []
        state.results.places = []
        state.results.hasNextPage = false
        state.results.nextCursor = nil
        state.results.isLoadingNextPage = false
        state.results.viewState = .emptyResults
    }

    private func resetSearch(state: inout State) {
        state.results.requestID += 1
        state.results.activeContext = nil
        state.results.regions = []
        state.results.relatedPlaceSuggestions = []
        state.results.places = []
        state.results.hasNextPage = false
        state.results.nextCursor = nil
        state.results.isLoadingNextPage = false
        state.results.viewState = .initial
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

    private func relatedSearchEffect(
        keyword: String,
        cursor: String?,
        requestID: Int,
        isAppending: Bool,
        delay: Bool
    ) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                if delay {
                    try await Task.sleep(for: .milliseconds(300))
                }
                let result = try await repository.fetchRelatedSearches(
                    query: PlaceRelatedSearchQuery(keyword: keyword, cursor: cursor)
                )
                await send(.relatedSearchLoaded(result, requestID: requestID, isAppending: isAppending))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.relatedSearchFailed(error, requestID: requestID, isAppending: isAppending))
            } catch {
                await send(.relatedSearchFailed(.unknown(errorCode: error.localizedDescription), requestID: requestID, isAppending: isAppending))
            }
        }
        .cancelTask(id: EffectID.search)
    }

    private func placeSearchEffect(
        keyword: String,
        cursor: String?,
        requestID: Int,
        isAppending: Bool,
        registration: RecentSearchRegistration?,
        origin: RodiCoordinate
    ) -> Effect<Action> {
        let placeRepository = placeRepository
        let recentSearchRepository = recentSearchRepository
        return .run { send in
            if let registration {
                do {
                    try await recentSearchRepository.registerRecentSearch(registration)
                } catch {
                    RodiLogger.warning("Recent region search registration failed. error=\(error.localizedDescription)")
                }
            }

            do {
                let page = try await placeRepository.searchPlaces(
                    query: PlaceSearchQuery(
                        keyword: keyword,
                        currentLatitude: origin.latitude,
                        currentLongitude: origin.longitude,
                        cursor: cursor
                    )
                )
                await send(.searchLoaded(page, requestID: requestID, isAppending: isAppending))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                await send(.searchFailed(error, requestID: requestID, isAppending: isAppending))
            } catch {
                await send(.searchFailed(.unknown(errorCode: error.localizedDescription), requestID: requestID, isAppending: isAppending))
            }
        }
        .cancelTask(id: EffectID.search)
    }

    private func selectPlaceEffect(
        id: Int,
        name: String,
        registration: RecentSearchRegistration?
    ) -> Effect<Action> {
        let repository = recentSearchRepository
        return .run { send in
            await send(.delegate(.placeSelected(id: id, name: name)))

            if let registration {
                do {
                    try await repository.registerRecentSearch(registration)
                } catch {
                    RodiLogger.warning("Recent place search registration failed. error=\(error.localizedDescription)")
                }
            }
        }
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

    private func showSnackbar(_ message: String) -> Effect<Action> {
        .send(.delegate(.showSnackbar(message)))
    }

    private func uniqueItems(_ items: [PlaceListItem]) -> [PlaceListItem] {
        var ids = Set<Int>()
        return items.filter { ids.insert($0.id).inserted }
    }

    private func uniqueSuggestions(
        _ suggestions: [PlaceRelatedSearchSuggestion]
    ) -> [PlaceRelatedSearchSuggestion] {
        var ids = Set<Int>()
        return suggestions.filter { ids.insert($0.id).inserted }
    }

    private func uniqueRegions(_ regions: [String]) -> [String] {
        var names = Set<String>()
        return regions.filter { names.insert($0).inserted }
    }

    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
