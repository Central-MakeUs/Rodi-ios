//
//  HomeSearchReducer.swift
//  Rodi
//

import Foundation

struct HomeSearchReducer: Reducer {
    enum SearchContext: Equatable {
        case suggestions(keyword: String)
        case selectedRegion(keyword: String)
    }

    enum ViewState: Equatable {
        case initial
        case searching
        case results
        case emptyResults
    }

    struct State {
        var query = ""
        var recentSearches: [RecentSearch] = []
        var regions: [String] = []
        var relatedPlaceSuggestions: [PlaceRelatedSearchSuggestion] = []
        var results: [PlaceListItem] = []
        var viewState: ViewState = .initial
        var isLoadingRecentSearches = false
        var isLoadingNextPage = false
        var hasNextPage = false
        var nextCursor: String?
        var snackbarMessage: String?
        var selectedPlaceID: Int?
        var selectedPlaceName: String?
        var searchRequestID = 0
        var activeSearchContext: SearchContext?
        var loadedSuggestionKeyword: String?
        var hasTrackedSearchOpen = false

        var isSelectedRegionSearch: Bool {
            if case .selectedRegion = activeSearchContext {
                return true
            }
            return false
        }
    }

    enum Action {
        case appeared
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
        case selectionHandled
        case dismissSnackbar
    }

    private enum EffectID: Hashable {
        case search
        case recentSearches
        case snackbar
    }

    private let placeRepository: PlaceRepository
    private let recentSearchRepository: RecentSearchRepository
    private let origin: RodiCoordinate

    init(
        placeRepository: PlaceRepository,
        recentSearchRepository: RecentSearchRepository,
        origin: RodiCoordinate
    ) {
        self.placeRepository = placeRepository
        self.recentSearchRepository = recentSearchRepository
        self.origin = origin
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            if !state.hasTrackedSearchOpen {
                state.hasTrackedSearchOpen = true
                RodiAnalytics.track(.searchOpened)
            }
            guard !state.isLoadingRecentSearches, state.recentSearches.isEmpty else { return .none }
            state.isLoadingRecentSearches = true
            return loadRecentSearchesEffect()

        case .queryChanged(let rawQuery):
            let query = String(rawQuery.prefix(50))
            state.query = query
            clearSelectedPlace(state: &state)
            state.loadedSuggestionKeyword = nil

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
            guard state.loadedSuggestionKeyword != query else { return .none }
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
                return beginPlaceSearch(keyword: recentSearch.keyword, state: &state)

            case .place:
                guard let placeID = recentSearch.placeID else {
                    return showSnackbar("장소 정보를 불러오지 못했어요.", state: &state)
                }
                selectPlace(id: placeID, name: recentSearch.keyword, state: &state)
                return .cancel(id: EffectID.search)
            }

        case .regionTapped(let region):
            state.query = region
            return beginPlaceSearch(keyword: region, state: &state, registration: .init(kind: .region, keyword: region))

        case .loadNextPage:
            guard state.hasNextPage,
                  !state.isLoadingNextPage,
                  let cursor = state.nextCursor
            else {
                return .none
            }
            state.isLoadingNextPage = true
            switch state.activeSearchContext {
            case .suggestions(let keyword):
                return relatedSearchEffect(
                    keyword: keyword,
                    cursor: cursor,
                    requestID: state.searchRequestID,
                    isAppending: true,
                    delay: false
                )
            case .selectedRegion(let keyword):
                return placeSearchEffect(
                    keyword: keyword,
                    cursor: cursor,
                    requestID: state.searchRequestID,
                    isAppending: true,
                    registration: nil
                )
            case nil:
                return .none
            }

        case let .relatedSearchLoaded(result, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  case .suggestions = state.activeSearchContext
            else {
                return .none
            }
            state.isLoadingNextPage = false
            state.loadedSuggestionKeyword = normalized(state.query)
            state.regions = isAppending ? uniqueRegions(state.regions + result.regions) : result.regions
            state.relatedPlaceSuggestions = isAppending
                ? uniqueSuggestions(state.relatedPlaceSuggestions + result.places.items)
                : result.places.items
            state.hasNextPage = result.places.hasNext
            state.nextCursor = result.places.nextCursor
            state.viewState = state.regions.isEmpty && state.relatedPlaceSuggestions.isEmpty ? .emptyResults : .results
            guard !isAppending else { return .none }
            RodiAnalytics.track(
                .searchResultsLoaded(
                    resultCountBucket: RodiAnalytics.countBucket(for: result.places.items.count),
                    hasRegionCandidates: !result.regions.isEmpty
                )
            )
            return .none

        case let .relatedSearchFailed(error, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  case .suggestions = state.activeSearchContext
            else {
                return .none
            }
            state.isLoadingNextPage = false
            if !isAppending, state.relatedPlaceSuggestions.isEmpty, state.regions.isEmpty {
                state.viewState = .emptyResults
            }
            return showSnackbar(error.localizedDescription, state: &state)

        case let .searchLoaded(page, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  case .selectedRegion = state.activeSearchContext
            else {
                return .none
            }
            state.isLoadingNextPage = false
            state.results = isAppending ? uniqueItems(state.results + page.items) : page.items
            state.hasNextPage = page.hasNext
            state.nextCursor = page.nextCursor
            state.viewState = state.results.isEmpty ? .emptyResults : .results
            return .none

        case let .searchFailed(error, requestID, isAppending):
            guard requestID == state.searchRequestID,
                  case .selectedRegion = state.activeSearchContext
            else {
                return .none
            }
            state.isLoadingNextPage = false
            if !isAppending, state.results.isEmpty {
                state.viewState = .emptyResults
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
            RodiAnalytics.track(.searchResultSelected(resultType: place.type.rawValue, source: "search_results"))
            selectPlace(id: place.id, name: place.name, state: &state)
            return registerRecentSearchEffect(.init(kind: .place, keyword: place.name, placeID: place.id))

        case .relatedPlaceSuggestionTapped(let suggestion):
            RodiAnalytics.track(.searchResultSelected(resultType: "RELATED_SUGGESTION", source: "search_suggestions"))
            selectPlace(id: suggestion.id, name: suggestion.name, state: &state)
            return registerRecentSearchEffect(
                .init(kind: .place, keyword: suggestion.name, placeID: suggestion.id)
            )

        case .selectionHandled:
            clearSelectedPlace(state: &state)
            return .none

        case .dismissSnackbar:
            state.snackbarMessage = nil
            return .none
        }
    }

    private func beginSuggestionSearch(
        keyword: String,
        delay: Bool,
        state: inout State
    ) -> Effect<Action> {
        state.searchRequestID += 1
        state.activeSearchContext = .suggestions(keyword: keyword)
        state.regions = []
        state.relatedPlaceSuggestions = []
        state.results = []
        state.hasNextPage = false
        state.nextCursor = nil
        state.isLoadingNextPage = false
        state.viewState = .searching
        return relatedSearchEffect(
            keyword: keyword,
            cursor: nil,
            requestID: state.searchRequestID,
            isAppending: false,
            delay: delay
        )
    }

    private func beginPlaceSearch(
        keyword: String,
        state: inout State,
        registration: RecentSearchRegistration? = nil
    ) -> Effect<Action> {
        state.searchRequestID += 1
        state.activeSearchContext = .selectedRegion(keyword: keyword)
        state.loadedSuggestionKeyword = nil
        state.regions = []
        state.relatedPlaceSuggestions = []
        state.results = []
        state.hasNextPage = false
        state.nextCursor = nil
        state.isLoadingNextPage = false
        state.viewState = .searching
        return placeSearchEffect(
            keyword: keyword,
            cursor: nil,
            requestID: state.searchRequestID,
            isAppending: false,
            registration: registration
        )
    }

    private func resetSearch(state: inout State) {
        state.searchRequestID += 1
        state.activeSearchContext = nil
        state.regions = []
        state.relatedPlaceSuggestions = []
        state.results = []
        state.hasNextPage = false
        state.nextCursor = nil
        state.isLoadingNextPage = false
        state.viewState = .initial
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
        registration: RecentSearchRegistration?
    ) -> Effect<Action> {
        let placeRepository = placeRepository
        let recentSearchRepository = recentSearchRepository
        let origin = origin
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

    private func registerRecentSearchEffect(_ registration: RecentSearchRegistration) -> Effect<Action> {
        let repository = recentSearchRepository
        return .run { _ in
            do {
                try await repository.registerRecentSearch(registration)
            } catch {
                RodiLogger.warning("Recent place search registration failed. error=\(error.localizedDescription)")
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

    private func showSnackbar(_ message: String, state: inout State) -> Effect<Action> {
        state.snackbarMessage = message
        return .run { send in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await send(.dismissSnackbar)
        }
        .cancelTask(id: EffectID.snackbar)
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

    private func selectPlace(id: Int, name: String, state: inout State) {
        state.selectedPlaceID = id
        state.selectedPlaceName = name
    }

    private func clearSelectedPlace(state: inout State) {
        state.selectedPlaceID = nil
        state.selectedPlaceName = nil
    }

    private func uniqueRegions(_ regions: [String]) -> [String] {
        var names = Set<String>()
        return regions.filter { names.insert($0).inserted }
    }

    private func normalized(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
