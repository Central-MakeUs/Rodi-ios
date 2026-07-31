//
//  HomeSearchView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct HomeSearchView: View {
    @StateObject private var store: StoreOf<HomeSearchReducer>
    @FocusState private var isSearchFieldFocused: Bool

    private let onPlaceSelected: (PlaceListItem) -> Void
    private let onAdministrativeAreaSelected: (AdministrativeAreaSearchResult) -> Void
    private let onDismiss: () -> Void

    init(
        origin: RodiCoordinate,
        onPlaceSelected: @escaping (PlaceListItem) -> Void,
        onAdministrativeAreaSelected: @escaping (AdministrativeAreaSearchResult) -> Void,
        onDismiss: @escaping () -> Void,
        placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository,
        recentSearchRepository: RecentSearchRepository = AuthDependencyContainer.shared.recentSearchRepository,
        administrativeAreaSearchService: KoreanAdministrativeAreaSearching = KoreanAdministrativeAreaSearchService.shared
    ) {
        self.onPlaceSelected = onPlaceSelected
        self.onAdministrativeAreaSelected = onAdministrativeAreaSelected
        self.onDismiss = onDismiss
        _store = StateObject(
            wrappedValue: Store(
                state: HomeSearchReducer.State(),
                reducer: HomeSearchReducer(
                    placeRepository: placeRepository,
                    recentSearchRepository: recentSearchRepository,
                    administrativeAreaSearchService: administrativeAreaSearchService,
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
                    } else if store.state.submittedQuery != nil {
                        searchSuggestions
                    } else {
                        EmptyView()
                    }
                }
                .padding(.top, store.state.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 24 : 0)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFieldFocused = false
            }
        }
        .background(RodiColor.white.ignoresSafeArea())
        .onAppear {
            store.send(.appeared)
            DispatchQueue.main.async {
                isSearchFieldFocused = true
            }
        }
        .onChange(of: store.state.selectedPlace) { place in
            guard let place else { return }
            isSearchFieldFocused = false
            onPlaceSelected(place)
            store.send(.selectionHandled)
        }
        .onChange(of: store.state.selectedAdministrativeAreaSearch) { result in
            guard let result else { return }
            isSearchFieldFocused = false
            onAdministrativeAreaSelected(result)
            store.send(.administrativeAreaSearchSelectionHandled)
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
        let hasAdministrativeAreas = !store.state.administrativeAreas.isEmpty
        let hasPlaceResults = !store.state.results.isEmpty || store.state.viewState == .searching || store.state.isLoadingNextPage

        if !hasAdministrativeAreas,
           !hasPlaceResults,
           store.state.viewState == .emptyResults {
            HomeSearchEmptyState(query: store.state.query)
        } else {
            if hasAdministrativeAreas {
                HomeAdministrativeAreaList(
                    areas: store.state.administrativeAreas,
                    selectAction: { store.send(.administrativeAreaTapped($0)) }
                )
            }

            if hasAdministrativeAreas, hasPlaceResults {
                Rectangle()
                    .fill(RodiColor.primaryMinus100)
                    .frame(height: 4)
            }

            if hasPlaceResults {
                HomeSearchResultList(
                    results: store.state.results,
                    isSearching: store.state.viewState == .searching,
                    isLoadingNextPage: store.state.isLoadingNextPage,
                    loadNextPage: { store.send(.loadNextPage) },
                    selectAction: { store.send(.resultTapped($0)) }
                )
            }
        }
    }

    private func dismiss() {
        isSearchFieldFocused = false
        onDismiss()
    }
}
