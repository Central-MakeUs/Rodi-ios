//
//  MySavedPlacesReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct MySavedPlacesReducer: Reducer {
    struct State {
        var items: [PlaceListItem] = []
        var totalCount: Int?
        var isInitialLoading = false
        var isNextPageLoading = false
        var errorMessage: String?
        fileprivate var nextCursor: String?
        fileprivate var hasNextPage = false
        var hasTrackedSavedPlacesOpen = false
    }

    enum Action {
        case appeared
        case retryTapped
        case lastItemAppeared(PlaceListItem)
        case firstPageLoaded(PageLoadResult)
        case nextPageLoaded(PageLoadResult)
    }

    enum PageLoadResult {
        case success(PlaceCursorPage)
        case failure(String)
    }

    private enum EffectID { case firstPage, nextPage }
    private let placeRepository: PlaceRepository

    init(placeRepository: PlaceRepository = AuthDependencyContainer.shared.placeRepository) {
        self.placeRepository = placeRepository
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .appeared:
            if !state.hasTrackedSavedPlacesOpen {
                state.hasTrackedSavedPlacesOpen = true
                RodiAnalytics.track(.savedPlacesOpened)
            }
            guard state.items.isEmpty, !state.isInitialLoading else { return .none }
            return loadFirstPage(state: &state)

        case .retryTapped:
            if state.items.isEmpty {
                guard !state.isInitialLoading else { return .none }
                return loadFirstPage(state: &state)
            }
            guard let lastItem = state.items.last else { return .none }
            return loadNextPage(after: lastItem, state: &state)

        case .lastItemAppeared(let item):
            return loadNextPage(after: item, state: &state)

        case .firstPageLoaded(let result):
            state.isInitialLoading = false
            switch result {
            case .success(let page):
                state.items = page.items
                state.totalCount = page.totalCount ?? page.items.count
                state.hasNextPage = page.hasNext
                state.nextCursor = page.nextCursor
                state.errorMessage = nil
            case .failure(let message):
                state.errorMessage = message
            }

        case .nextPageLoaded(let result):
            state.isNextPageLoading = false
            switch result {
            case .success(let page):
                let existingIDs = Set(state.items.map(\.id))
                state.items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
                state.hasNextPage = page.hasNext
                state.nextCursor = page.nextCursor
                state.errorMessage = nil
            case .failure(let message):
                state.errorMessage = message
            }
        }

        return .none
    }
}

private extension MySavedPlacesReducer {
    func loadFirstPage(state: inout State) -> Effect<Action> {
        state.isInitialLoading = true
        state.errorMessage = nil
        return .run { send in
            do {
                let page = try await placeRepository.fetchBookmarkedPlaces(query: PlaceBookmarkListQuery())
                await send(.firstPageLoaded(.success(page)))
            } catch {
                await send(.firstPageLoaded(.failure(message(for: error))))
            }
        }
        .cancelTask(id: EffectID.firstPage)
    }

    func loadNextPage(after item: PlaceListItem, state: inout State) -> Effect<Action> {
        guard item.id == state.items.last?.id,
              state.hasNextPage,
              let cursor = state.nextCursor,
              !state.isInitialLoading,
              !state.isNextPageLoading else {
            return .none
        }

        state.isNextPageLoading = true
        state.errorMessage = nil
        return .run { send in
            do {
                let page = try await placeRepository.fetchBookmarkedPlaces(
                    query: PlaceBookmarkListQuery(cursor: cursor)
                )
                await send(.nextPageLoaded(.success(page)))
            } catch {
                await send(.nextPageLoaded(.failure(message(for: error))))
            }
        }
        .cancelTask(id: EffectID.nextPage)
    }

    func message(for error: Error) -> String {
        if case NetworkError.networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "저장 목록을 불러오지 못했어요."
    }
}
