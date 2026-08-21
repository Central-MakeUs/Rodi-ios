//
//  CourseRegistrationPlaceSearchReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct CourseRegistrationPlaceSearchReducer: Reducer {
    struct State: Equatable {
        var query: String
        var regions: [CourseRegistrationRegionSuggestion] = []
        var places: [CourseRegistrationPlaceSearchItem] = []
        var isPlaceLoading = false
        var isLoadingNextPage = false
        var isPlaceSearchEnd = false
        var hasSearchedPlaces = false
        var placeErrorMessage: String?
        var requestID = 0
        let sessionID: UUID

        init(initialQuery: String = "") {
            query = initialQuery
            sessionID = UUID()
        }
    }

    enum Action {
        case appeared
        case queryChanged(String)
        case regionTapped(CourseRegistrationRegionSuggestion)
        case sampleSearchTapped(String)
        case searchTapped
        case loadNextPage
        case resultTapped(CourseRegistrationPlaceSearchItem)
        case closeTapped
        case deactivated
        case placeSearchCompleted(SearchResult, sessionID: UUID, requestID: Int, isNextPage: Bool)
        case delegate(Delegate)
    }

    enum Delegate {
        case resultSelected(CourseRegistrationPlaceSearchItem)
        case regionSelected(CourseRegistrationRegionSuggestion)
        case closeRequested
    }

    enum SearchResult {
        case success(CourseRegistrationPlaceSearchPage)
        case failure(String)
    }

    private enum EffectID: Hashable {
        case placeSearch
    }

    private let regionService: CourseRegistrationAdministrativeRegionService
    private let searchService: KakaoLocalPlaceSearchService

    init(
        regionService: CourseRegistrationAdministrativeRegionService,
        searchService: KakaoLocalPlaceSearchService
    ) {
        self.regionService = regionService
        self.searchService = searchService
    }

    init() {
        regionService = CourseRegistrationAdministrativeRegionService()
        searchService = KakaoLocalPlaceSearchService()
    }
}

// MARK: - Reduce
extension CourseRegistrationPlaceSearchReducer {
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            guard !state.hasSearchedPlaces, !state.isPlaceLoading else { return .none }
            updateRegions(state: &state)
            return searchPlaces(state: &state, debounce: false)

        case .queryChanged(let query):
            state.query = query
            updateRegions(state: &state)
            return searchPlaces(state: &state, debounce: true)

        case .regionTapped(let region):
            return .send(.delegate(.regionSelected(region)))

        case .sampleSearchTapped(let query):
            state.query = query
            updateRegions(state: &state)
            return searchPlaces(state: &state, debounce: false)

        case .searchTapped:
            updateRegions(state: &state)
            return searchPlaces(state: &state, debounce: false)

        case .loadNextPage:
            guard state.hasSearchedPlaces,
                  !state.isPlaceLoading,
                  !state.isLoadingNextPage,
                  !state.isPlaceSearchEnd,
                  !state.places.isEmpty
            else {
                return .none
            }
            return searchPlaces(
                state: &state,
                offset: state.places.count,
                isNextPage: true,
                debounce: false
            )

        case .resultTapped(let result):
            return .send(.delegate(.resultSelected(result)))

        case .closeTapped:
            return .send(.delegate(.closeRequested))

        case .deactivated:
            state.requestID += 1
            state.isPlaceLoading = false
            state.isLoadingNextPage = false
            return .cancel(id: EffectID.placeSearch)

        case let .placeSearchCompleted(result, sessionID, requestID, isNextPage):
            guard sessionID == state.sessionID, requestID == state.requestID else { return .none }
            state.isPlaceLoading = false
            state.isLoadingNextPage = false
            state.hasSearchedPlaces = true

            switch result {
            case .success(let page):
                state.places = isNextPage ? state.places + page.items : page.items
                state.isPlaceSearchEnd = page.isEnd
                state.placeErrorMessage = nil
            case .failure(let message):
                if isNextPage {
                    state.placeErrorMessage = nil
                } else {
                    state.places = []
                    state.placeErrorMessage = message
                }
            }

        case .delegate:
            return .none
        }

        return .none
    }
}

// MARK: - State Mutation
private extension CourseRegistrationPlaceSearchReducer {
    func updateRegions(state: inout State) {
        state.regions = regionService.suggestions(for: state.query, limit: 4)
    }
}

// MARK: - Effect
private extension CourseRegistrationPlaceSearchReducer {
    func searchPlaces(
        state: inout State,
        offset: Int = 0,
        isNextPage: Bool = false,
        debounce: Bool
    ) -> Effect<Action> {
        let query = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.requestID += 1

        guard query.count >= 2 else {
            state.places = []
            state.isPlaceLoading = false
            state.hasSearchedPlaces = false
            state.isLoadingNextPage = false
            state.isPlaceSearchEnd = false
            state.placeErrorMessage = nil
            return .cancel(id: EffectID.placeSearch)
        }

        if isNextPage {
            state.isLoadingNextPage = true
        } else {
            state.places = []
            state.isPlaceLoading = true
            state.isLoadingNextPage = false
            state.isPlaceSearchEnd = false
            state.hasSearchedPlaces = false
        }
        state.placeErrorMessage = nil

        let requestID = state.requestID
        let sessionID = state.sessionID
        let searchService = searchService

        return .run { send in
            if debounce {
                do {
                    try await Task.sleep(for: .milliseconds(300))
                } catch {
                    return
                }
            }

            do {
                let page = try await searchService.searchPlaces(query: query, offset: offset)
                await send(.placeSearchCompleted(
                    .success(page),
                    sessionID: sessionID,
                    requestID: requestID,
                    isNextPage: isNextPage
                ))
            } catch is CancellationError {
                return
            } catch let error as KakaoLocalPlaceSearchError {
                await send(.placeSearchCompleted(
                    .failure(error.userMessage),
                    sessionID: sessionID,
                    requestID: requestID,
                    isNextPage: isNextPage
                ))
            } catch {
                await send(
                    .placeSearchCompleted(
                        .failure("검색 중 알 수 없는 오류가 발생했어요."),
                        sessionID: sessionID,
                        requestID: requestID,
                        isNextPage: isNextPage
                    )
                )
            }
        }
        .cancelTask(id: EffectID.placeSearch)
    }
}
