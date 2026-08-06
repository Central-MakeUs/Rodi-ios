//
//  RecommendListBottomSheetReducer.swift
//  Rodi
//

import Foundation

struct RecommendListBottomSheetReducer: Reducer {
    enum Presentation: Equatable {
        case collapsed
        case medium
        case expanded
    }

    struct State {
        var items: [PlaceListItem] = []
        var activeViewport: PlaceViewport?
        var latestViewport: PlaceViewport?
        var latestViewportCenter: RodiCoordinate?
        var pendingInitialSearchOrigin: RodiCoordinate?
        var requestOrigin: RodiCoordinate?
        var nextCursor: String?
        var hasNext = false
        var isInitialLoading = false
        var isNextPageLoading = false
        var isManualResearchLoading = false
        var errorMessage: String?
        var needsResearch = false
        var requestRevision = 0
        var presentation: Presentation = .collapsed
    }

    enum Action {
        case present
        case collapse
        case expand
        case viewportChanged(viewport: PlaceViewport, center: RodiCoordinate, isUserInitiated: Bool)
        case prepareInitialSearch(origin: RodiCoordinate)
        case reloadCurrentViewport(origin: RodiCoordinate?)
        case reloadAfterFilter
        case loadNextPage
        case pageLoaded(
            page: PlaceCursorPage,
            viewport: PlaceViewport,
            revision: Int,
            isAppending: Bool,
            isManualResearch: Bool
        )
        case pageFailed(message: String, revision: Int, isAppending: Bool, isManualResearch: Bool)
        case select(PlaceListItem)
        case openFilter
        case delegate(Delegate)
    }

    enum Delegate {
        case resolvePlace(PlaceListItem)
        case presentFilter
        case requestAuthentication
        case showSnackbar(String)
        case displayStateChanged(presentation: Presentation, showsResearchButton: Bool)
    }

    private let placeRepository: PlaceRepository
    private let hasActiveSession: () -> Bool
    private let onDelegate: (Delegate) -> Void

    init(
        placeRepository: PlaceRepository,
        hasActiveSession: @escaping () -> Bool,
        onDelegate: @escaping (Delegate) -> Void = { _ in }
    ) {
        self.placeRepository = placeRepository
        self.hasActiveSession = hasActiveSession
        self.onDelegate = onDelegate
    }
}


// MARK: - Core Logics
extension RecommendListBottomSheetReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .present:
            state.presentation = .medium
            return displayStateEffect(state)

        case .collapse:
            state.presentation = .collapsed
            return displayStateEffect(state)

        case .expand:
            state.presentation = .expanded
            return displayStateEffect(state)

        case let .viewportChanged(viewport, center, isUserInitiated):
            let previousViewport = state.latestViewport
            state.latestViewport = viewport
            state.latestViewportCenter = center

            if state.isManualResearchLoading, previousViewport != viewport {
                state.requestRevision += 1
                state.isInitialLoading = false
                state.isManualResearchLoading = false
                state.needsResearch = true
                return .cancel(id: BottomSheetEffectID.placeListLoading)
            }

            if isUserInitiated {
                let hasInFlightRequest = state.isInitialLoading || state.isNextPageLoading
                if hasInFlightRequest {
                    state.requestRevision += 1
                    state.isInitialLoading = false
                    state.isNextPageLoading = false
                    state.isManualResearchLoading = false
                    state.needsResearch = true
                    return .cancel(id: BottomSheetEffectID.placeListLoading)
                }
                if state.activeViewport != nil { state.needsResearch = true }
                if state.activeViewport != nil { return displayStateEffect(state) }
            }

            if state.activeViewport == nil,
               let origin = state.pendingInitialSearchOrigin,
               center.distanceKilometers(to: origin) <= 0.5,
               !state.isInitialLoading {
                return loadFirstPage(viewport: viewport, origin: origin, state: &state, isManualResearch: false)
            }

        case .prepareInitialSearch(let origin):
            guard state.activeViewport == nil else { return .none }
            state.pendingInitialSearchOrigin = origin
            if let viewport = state.latestViewport,
               let center = state.latestViewportCenter,
               center.distanceKilometers(to: origin) <= 0.5 {
                return .send(.viewportChanged(viewport: viewport, center: center, isUserInitiated: false))
            }

        case .reloadCurrentViewport(let origin):
            guard let viewport = state.latestViewport,
                  let center = state.latestViewportCenter,
                  !state.isInitialLoading,
                  !state.isNextPageLoading else { return .none }
            return loadFirstPage(viewport: viewport, origin: origin ?? center, state: &state, isManualResearch: true)

        case .reloadAfterFilter:
            guard let viewport = state.latestViewport,
                  let origin = state.requestOrigin ?? state.latestViewportCenter,
                  !state.isInitialLoading,
                  !state.isNextPageLoading else { return .none }
            return loadFirstPage(viewport: viewport, origin: origin, state: &state, isManualResearch: false)

        case .loadNextPage:
            guard !state.needsResearch,
                  !state.isInitialLoading,
                  !state.isNextPageLoading,
                  state.hasNext,
                  let viewport = state.activeViewport,
                  let origin = state.requestOrigin,
                  let cursor = state.nextCursor,
                  !cursor.isEmpty else { return .none }
            state.isNextPageLoading = true
            state.errorMessage = nil
            return loadPageEffect(viewport: viewport, origin: origin, cursor: cursor, revision: state.requestRevision, isAppending: true, isManualResearch: false)

        case let .pageLoaded(page, viewport, revision, isAppending, isManualResearch):
            guard revision == state.requestRevision else { return .none }
            if isAppending {
                let existingIDs = Set(state.items.map(\.id))
                state.items += page.items.filter { !existingIDs.contains($0.id) }
            } else {
                state.items = page.items
                state.activeViewport = viewport
                state.pendingInitialSearchOrigin = nil
                state.needsResearch = false
            }
            state.hasNext = page.hasNext
            state.nextCursor = page.nextCursor
            state.isInitialLoading = false
            state.isNextPageLoading = false
            state.isManualResearchLoading = false
            state.errorMessage = nil
            if !isAppending,
               isManualResearch,
               state.presentation == .collapsed {
                state.presentation = .medium
            }
            return displayStateEffect(state)

        case let .pageFailed(message, revision, isAppending, isManualResearch):
            guard revision == state.requestRevision else { return .none }
            state.isInitialLoading = false
            state.isNextPageLoading = false
            state.isManualResearchLoading = false
            state.errorMessage = message
            if !isAppending { state.needsResearch = true }
            if !isAppending { return displayStateEffect(state) }
            if isManualResearch { return .send(.delegate(.showSnackbar(message))) }

        case .select(let item):
            return .send(.delegate(.resolvePlace(item)))

        case .openFilter:
            guard hasActiveSession() else { return .send(.delegate(.requestAuthentication)) }
            return .send(.delegate(.presentFilter))

        case .delegate(let delegate):
            onDelegate(delegate)
        }

        return .none
    }

    private func loadFirstPage(viewport: PlaceViewport, origin: RodiCoordinate, state: inout State, isManualResearch: Bool) -> Effect<Action> {
        state.requestRevision += 1
        state.isInitialLoading = true
        state.isNextPageLoading = false
        state.isManualResearchLoading = isManualResearch
        state.errorMessage = nil
        state.requestOrigin = origin
        state.nextCursor = nil
        state.hasNext = false
        return loadPageEffect(viewport: viewport, origin: origin, cursor: nil, revision: state.requestRevision, isAppending: false, isManualResearch: isManualResearch)
    }

    private func loadPageEffect(viewport: PlaceViewport, origin: RodiCoordinate, cursor: String?, revision: Int, isAppending: Bool, isManualResearch: Bool) -> Effect<Action> {
        let repository = placeRepository
        let access: PlaceListAccess = hasActiveSession() ? .member : .public
        let query = PlaceListQuery(viewport: viewport, currentLatitude: origin.latitude, currentLongitude: origin.longitude, size: 20, cursor: cursor)
        return .run { send in
            do {
                if isManualResearch { try await Task.sleep(for: .milliseconds(350)) }
                let page = try await repository.fetchPlaces(query: query, access: access)
                await send(.pageLoaded(
                    page: page,
                    viewport: viewport,
                    revision: revision,
                    isAppending: isAppending,
                    isManualResearch: isManualResearch
                ))
            } catch is CancellationError {
                return
            } catch {
                await send(.pageFailed(message: "추천 목록을 불러오지 못했어요.", revision: revision, isAppending: isAppending, isManualResearch: isManualResearch))
            }
        }
        .cancelTask(id: BottomSheetEffectID.placeListLoading)
    }

    private func displayStateEffect(_ state: State) -> Effect<Action> {
        .send(.delegate(.displayStateChanged(
            presentation: state.presentation,
            showsResearchButton: state.needsResearch
        )))
    }
}
