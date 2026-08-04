//
//  HomeSearchView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct HomeSearchView: View {
    @StateObject private var store: StoreOf<HomeSearchReducer>
    @FocusState private var isSearchFieldFocused: Bool

    private let onPlaceSelected: (Int, String) -> Void
    private let onDismiss: () -> Void

    init(
        origin: RodiCoordinate,
        onPlaceSelected: @escaping (Int, String) -> Void,
        onDismiss: @escaping () -> Void,
        placeRepository: PlaceRepository,
        recentSearchRepository: RecentSearchRepository
    ) {
        self.onPlaceSelected = onPlaceSelected
        self.onDismiss = onDismiss
        _store = StateObject(
            wrappedValue: Store(
                state: HomeSearchReducer.State(),
                reducer: HomeSearchReducer(
                    placeRepository: placeRepository,
                    recentSearchRepository: recentSearchRepository,
                    origin: origin
                )
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeSearchTextField(
                text: queryBinding,
                isFocused: $isSearchFieldFocused,
                backAction: dismiss,
                submitAction: { store.send(.searchSubmitted) }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 5)
            .background(RodiColor.white)
            .clarityMask()

            GeometryReader { geometry in
                ScrollView {
                    Group {
                        if store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HomeRecentSearchList(
                                searches: store.state.recentSearches,
                                isLoading: store.state.isLoadingRecentSearches,
                                selectAction: { store.send(.recentSearchTapped($0)) },
                                deleteAction: { store.send(.recentSearchDeleteTapped($0)) },
                                clearAllAction: { store.send(.clearAllRecentSearchesTapped) }
                            )
                            .padding(.horizontal, 16)
                        } else {
                            searchSuggestions
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: shouldCenterRegionEmptyState ? geometry.size.height : nil,
                        alignment: .center
                    )
                    .padding(.top, store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 24 : 0)
                    .padding(.bottom, shouldCenterRegionEmptyState ? 0 : 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFieldFocused = false
                }
            }
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onAppear {
            store.send(.appeared)
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: store.state.selectedPlaceID) { placeID in
            guard let placeID, let placeName = store.state.selectedPlaceName else { return }
            isSearchFieldFocused = false
            onPlaceSelected(placeID, placeName)
            store.send(.selectionHandled)
        }
        .rodiSnackbar(message: store.state.snackbarMessage)
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { store.state.query },
            set: { store.send(.queryChanged($0)) }
        )
    }

    @ViewBuilder
    private var searchSuggestions: some View {
        let hasRegions = !store.state.regions.isEmpty
        let isSelectedRegionSearch = store.state.isSelectedRegionSearch
        let hasPlaces = isSelectedRegionSearch
            ? !store.state.results.isEmpty || store.state.viewState == .searching || store.state.isLoadingNextPage
            : !store.state.relatedPlaceSuggestions.isEmpty || store.state.viewState == .searching || store.state.isLoadingNextPage

        if !hasRegions,
           !hasPlaces,
           store.state.viewState == .emptyResults {
            if isSelectedRegionSearch {
                HomeSearchRegionEmptyState()
            } else {
                HomeSearchEmptyState(query: store.state.query)
            }
        } else {
            if hasRegions {
                HomeSearchRegionList(
                    regions: store.state.regions,
                    selectAction: { store.send(.regionTapped($0)) }
                )
            }

            if hasRegions, hasPlaces {
                RodiColor.primaryMinus100
                    .frame(height: 4)
            }

            if hasPlaces {
                if isSelectedRegionSearch {
                    HomeSearchResultList(
                        results: store.state.results,
                        isSearching: store.state.viewState == .searching,
                        isLoadingNextPage: store.state.isLoadingNextPage,
                        showsEmptyMessage: false,
                        loadNextPage: { store.send(.loadNextPage) },
                        selectAction: { store.send(.resultTapped($0)) }
                    )
                } else {
                    HomeRelatedSearchPlaceList(
                        suggestions: store.state.relatedPlaceSuggestions,
                        isSearching: store.state.viewState == .searching,
                        isLoadingNextPage: store.state.isLoadingNextPage,
                        showsEmptyMessage: !hasRegions,
                        loadNextPage: { store.send(.loadNextPage) },
                        selectAction: { store.send(.relatedPlaceSuggestionTapped($0)) }
                    )
                }
            }
        }
    }

    private var shouldCenterRegionEmptyState: Bool {
        store.state.isSelectedRegionSearch &&
            store.state.viewState == .emptyResults &&
            store.state.regions.isEmpty &&
            store.state.results.isEmpty
    }

    private func dismiss() {
        isSearchFieldFocused = false
        onDismiss()
    }
}
