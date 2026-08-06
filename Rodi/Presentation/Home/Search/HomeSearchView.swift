//
//  HomeSearchView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct HomeSearchView: View {
    @FocusState private var isSearchFieldFocused: Bool
    let state: HomeSearchReducer.State
    let send: (HomeSearchReducer.Action) -> Void
    private let origin: RodiCoordinate

    init(
        origin: RodiCoordinate,
        state: HomeSearchReducer.State,
        send: @escaping (HomeSearchReducer.Action) -> Void
    ) {
        self.origin = origin
        self.state = state
        self.send = send
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeSearchTextField(
                text: queryBinding,
                isFocused: $isSearchFieldFocused,
                backAction: dismiss,
                submitAction: { send(.searchSubmitted) }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .background(RodiColor.white)
            .clarityMask()

            ZStack {
                ScrollView {
                    searchContent
                    .padding(.top, state.query.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty ? 24 : 0)
                    .padding(.bottom, shouldCenterRegionEmptyState ? 0 : 32)
                }

                if shouldCenterRegionEmptyState {
                    HomeSearchRegionEmptyState()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFieldFocused = false
            }
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onAppear {
            send(.appeared(origin: origin))
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
    }
}

// MARK: Layout
extension HomeSearchView {

    private var queryBinding: Binding<String> {
        Binding(
            get: { state.query },
            set: { send(.queryChanged($0)) }
        )
    }

    @ViewBuilder
    private var searchContent: some View {
        if state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HomeRecentSearchList(
                searches: state.recentSearches,
                isLoading: state.isLoadingRecentSearches,
                selectAction: { send(.recentSearchTapped($0)) },
                deleteAction: { send(.recentSearchDeleteTapped($0)) },
                clearAllAction: { send(.clearAllRecentSearchesTapped) }
            )
            .padding(.horizontal, 16)
        } else {
            searchSuggestions
        }
    }

    @ViewBuilder
    private var searchSuggestions: some View {
        let hasRegions = !state.regions.isEmpty
        let isSelectedRegionSearch = state.isSelectedRegionSearch
        let hasPlaces = isSelectedRegionSearch
            ? !state.results.isEmpty || state.viewState == .searching || state.isLoadingNextPage
            : !state.relatedPlaceSuggestions.isEmpty || state.viewState == .searching || state.isLoadingNextPage

        if !hasRegions,
           !hasPlaces,
           state.viewState == .emptyResults {
            if !isSelectedRegionSearch {
                HomeSearchEmptyState(query: state.query)
            }
        } else {
            if hasRegions {
                HomeSearchRegionList(
                    regions: state.regions,
                    selectAction: { send(.regionTapped($0)) }
                )
            }

            if hasRegions, hasPlaces {
                RodiColor.primaryMinus100
                    .frame(height: 4)
            }

            if hasPlaces {
                if isSelectedRegionSearch {
                    HomeSearchResultList(
                        results: state.results,
                        isSearching: state.viewState == .searching,
                        isLoadingNextPage: state.isLoadingNextPage,
                        showsEmptyMessage: false,
                        loadNextPage: { send(.loadNextPage) },
                        selectAction: { send(.resultTapped($0)) }
                    )
                } else {
                    HomeRelatedSearchPlaceList(
                        suggestions: state.relatedPlaceSuggestions,
                        isSearching: state.viewState == .searching,
                        isLoadingNextPage: state.isLoadingNextPage,
                        showsEmptyMessage: !hasRegions,
                        loadNextPage: { send(.loadNextPage) },
                        selectAction: { send(.relatedPlaceSuggestionTapped($0)) }
                    )
                }
            }
        }
    }

    private var shouldCenterRegionEmptyState: Bool {
        state.isSelectedRegionSearch &&
            state.viewState == .emptyResults &&
            state.regions.isEmpty &&
            state.results.isEmpty
    }

    private func dismiss() {
        isSearchFieldFocused = false
        send(.dismissTapped)
    }
}
