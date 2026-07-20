//
//  HomeReducer+PlaceList.swift
//  Rodi
//

import Foundation

extension HomeReducer {
    func reducePlaceListAction(
        _ action: HomeAction.PlaceListAction,
        state: inout HomeState
    ) -> Effect<HomeAction> {
        switch action {
        case let .viewportChanged(viewport, center, isUserInitiated):
            state.placeList.latestViewport = viewport
            state.placeList.latestViewportCenter = center

            if isUserInitiated {
                let hadInFlightRequest = state.placeList.isInitialLoading || state.placeList.isNextPageLoading
                if hadInFlightRequest {
                    // 이전 bounds 응답이 새 지도 화면의 목록을 덮어쓰지 못하게 무효화한다.
                    state.placeList.requestRevision += 1
                    state.placeList.isInitialLoading = false
                    state.placeList.isNextPageLoading = false
                }

                if state.placeList.activeViewport != nil || hadInFlightRequest {
                    state.placeList.needsResearch = true
                }

                if hadInFlightRequest {
                    return .cancel(id: HomeEffectID.placeListLoading)
                }
            }

            if state.placeList.activeViewport == nil,
               let origin = state.placeList.pendingInitialSearchOrigin,
               center.distanceKilometers(to: origin) <= 0.5,
               !state.placeList.isInitialLoading {
                return loadFirstPage(
                    viewport: viewport,
                    origin: origin,
                    state: &state
                )
            }

        case .reloadCurrentViewport:
            guard let viewport = state.placeList.latestViewport,
                  let center = state.placeList.latestViewportCenter
            else {
                return .none
            }

            let origin = state.location.userLocationCoordinate ?? center
            return loadFirstPage(viewport: viewport, origin: origin, state: &state)

        case .loadNextPage:
            guard !state.placeList.needsResearch,
                  !state.placeList.isInitialLoading,
                  !state.placeList.isNextPageLoading,
                  state.placeList.hasNext,
                  let viewport = state.placeList.activeViewport,
                  let origin = state.placeList.requestOrigin,
                  let cursor = state.placeList.nextCursor,
                  !cursor.isEmpty
            else {
                return .none
            }

            state.placeList.isNextPageLoading = true
            state.placeList.errorMessage = nil
            return loadPageEffect(
                viewport: viewport,
                origin: origin,
                cursor: cursor,
                revision: state.placeList.requestRevision,
                isAppending: true
            )

        case let .pageLoaded(page, viewport, revision, isAppending):
            guard revision == state.placeList.requestRevision else { return .none }

            if isAppending {
                let existingIDs = Set(state.placeList.items.map(\.id))
                state.placeList.items += page.items.filter { !existingIDs.contains($0.id) }
            } else {
                state.placeList.items = page.items
                state.placeList.activeViewport = viewport
                state.placeList.pendingInitialSearchOrigin = nil
                state.placeList.needsResearch = false
            }

            state.placeList.hasNext = page.hasNext
            state.placeList.nextCursor = page.nextCursor
            state.placeList.totalCount = page.totalCount
            state.placeList.isInitialLoading = false
            state.placeList.isNextPageLoading = false
            state.placeList.errorMessage = nil

        case let .pageFailed(message, revision, isAppending):
            guard revision == state.placeList.requestRevision else { return .none }
            state.placeList.isInitialLoading = false
            state.placeList.isNextPageLoading = false
            state.placeList.errorMessage = message
            if !isAppending {
                state.placeList.needsResearch = true
            }
        }

        return .none
    }

    private func loadFirstPage(
        viewport: PlaceViewport,
        origin: RodiCoordinate,
        state: inout HomeState
    ) -> Effect<HomeAction> {
        state.placeList.requestRevision += 1
        state.placeList.isInitialLoading = true
        state.placeList.isNextPageLoading = false
        state.placeList.errorMessage = nil
        state.placeList.requestOrigin = origin
        state.placeList.nextCursor = nil
        state.placeList.hasNext = false

        return loadPageEffect(
            viewport: viewport,
            origin: origin,
            cursor: nil,
            revision: state.placeList.requestRevision,
            isAppending: false
        )
    }

    private func loadPageEffect(
        viewport: PlaceViewport,
        origin: RodiCoordinate,
        cursor: String?,
        revision: Int,
        isAppending: Bool
    ) -> Effect<HomeAction> {
        let repository = placeRepository
        let query = PlaceListQuery(
            viewport: viewport,
            currentLatitude: origin.latitude,
            currentLongitude: origin.longitude,
            size: 20,
            cursor: cursor
        )

        return .run { send in
            do {
                let page = try await repository.fetchPlaces(query: query)
                await send(.placeListAction(.pageLoaded(
                    page: page,
                    viewport: viewport,
                    revision: revision,
                    isAppending: isAppending
                )))
                RodiLogger.info(
                    "Home place list loaded revision=\(revision), append=\(isAppending), count=\(page.items.count), hasNext=\(page.hasNext)"
                )
            } catch is CancellationError {
                RodiLogger.info("Home place list request cancelled revision=\(revision), append=\(isAppending)")
            } catch {
                RodiLogger.warning(
                    "Home place list request failed revision=\(revision), append=\(isAppending), error=\(error.localizedDescription)"
                )
                await send(.placeListAction(.pageFailed(
                    message: "추천 목록을 불러오지 못했어요.",
                    revision: revision,
                    isAppending: isAppending
                )))
            }
        }
        .cancelTask(id: HomeEffectID.placeListLoading)
    }
}
