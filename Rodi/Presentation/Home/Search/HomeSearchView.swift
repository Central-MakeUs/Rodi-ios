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
                    ).isEmpty ? 3 : 0)
                    .padding(.bottom, showsCenteredEmptyState ? 0 : 32)
                }

                if shouldCenterRecentSearchEmptyState {
                    HomeSearchEmptyState()
                } else if shouldCenterEmptyState {
                    HomeSearchEmptyState(query: state.query)
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
                searches: state.recent.searches,
                isLoading: state.recent.isLoading,
                selectAction: { send(.recentSearchTapped($0)) },
                deleteAction: { send(.recentSearchDeleteTapped($0)) },
                clearAllAction: { send(.clearAllRecentSearchesTapped) }
            )
        } else {
            searchSuggestions
        }
    }

    @ViewBuilder
    private var searchSuggestions: some View {
        let hasRegions = !state.results.regions.isEmpty
        let isSelectedRegionSearch = state.results.isSelectedRegionSearch
        let hasPlaces = isSelectedRegionSearch
            ? !state.results.places.isEmpty || state.results.viewState == .searching || state.results.isLoadingNextPage
            : !state.results.relatedPlaceSuggestions.isEmpty || state.results.viewState == .searching || state.results.isLoadingNextPage

        if !hasRegions,
           !hasPlaces,
           state.results.viewState == .emptyResults {
            EmptyView()
        } else {
            if hasRegions {
                HomeSearchRegionList(
                    regions: state.results.regions,
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
                        results: state.results.places,
                        isSearching: state.results.viewState == .searching,
                        isLoadingNextPage: state.results.isLoadingNextPage,
                        showsEmptyMessage: false,
                        loadNextPage: { send(.loadNextPage) },
                        selectAction: { send(.resultTapped($0)) }
                    )
                } else {
                    HomeRelatedSearchPlaceList(
                        suggestions: state.results.relatedPlaceSuggestions,
                        isSearching: state.results.viewState == .searching,
                        isLoadingNextPage: state.results.isLoadingNextPage,
                        showsEmptyMessage: !hasRegions,
                        loadNextPage: { send(.loadNextPage) },
                        selectAction: { send(.relatedPlaceSuggestionTapped($0)) }
                    )
                }
            }
        }
    }

    private var shouldCenterEmptyState: Bool {
        !state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            state.results.viewState == .emptyResults &&
            state.results.regions.isEmpty &&
            state.results.relatedPlaceSuggestions.isEmpty &&
            state.results.places.isEmpty
    }

    private var shouldCenterRecentSearchEmptyState: Bool {
        state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !state.recent.isLoading &&
            state.recent.searches.isEmpty
    }

    private var showsCenteredEmptyState: Bool {
        shouldCenterEmptyState || shouldCenterRecentSearchEmptyState
    }

    private func dismiss() {
        isSearchFieldFocused = false
        send(.dismissTapped)
    }
}
