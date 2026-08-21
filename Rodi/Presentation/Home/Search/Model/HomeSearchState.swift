//
//  HomeSearchState.swift
//  Rodi
//

import Foundation

enum HomeSearchContext: Equatable {
    case suggestions(keyword: String)
    case selectedRegion(keyword: String)
}

enum HomeSearchViewState: Equatable {
    case initial
    case searching
    case results
    case emptyResults
}

/// 최근 검색 목록의 로딩과 표시 상태다.
struct HomeRecentSearchState {
    var searches: [RecentSearch] = []
    var isLoading = false
}

/// 현재 검색어에 대한 연관 검색·장소 결과·cursor 상태다.
struct HomeSearchResultsState {
    var regions: [String] = []
    var relatedPlaceSuggestions: [PlaceRelatedSearchSuggestion] = []
    var places: [PlaceListItem] = []
    var viewState: HomeSearchViewState = .initial
    var isLoadingNextPage = false
    var hasNextPage = false
    var nextCursor: String?
    var requestID = 0
    var activeContext: HomeSearchContext?
    var loadedSuggestionKeyword: String?

    var isSelectedRegionSearch: Bool {
        if case .selectedRegion = activeContext {
            return true
        }
        return false
    }
}

/// 검색 입력과 독립적인 최근 검색·결과 상태를 조립하는 Feature root 상태다.
struct HomeSearchState {
    var origin: RodiCoordinate = .southKoreaCenter
    var query = ""
    var recent = HomeRecentSearchState()
    var results = HomeSearchResultsState()
    var hasTrackedSearchOpen = false
}
