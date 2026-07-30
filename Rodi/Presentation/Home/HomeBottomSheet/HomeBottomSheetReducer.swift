//
//  HomeBottomSheetReducer.swift
//  Rodi
//

import Foundation

struct HomeBottomSheetReducer: Reducer {
    struct State {
        struct FilterState {
            var isPresented = false
            var appliedSelection: HomePracticeFilterSelection
            var draftSelection: HomePracticeFilterSelection
            var isApplying = false

            init(filterStore: HomePracticeFilterStore = HomePracticeFilterStore()) {
                let selection = filterStore.load()
                appliedSelection = selection
                draftSelection = selection
            }

            var canApply: Bool {
                !isApplying && draftSelection.filterTags != appliedSelection.filterTags
            }
        }

        struct PlaceListState {
            var items: [PlaceListItem] = []
            var activeViewport: PlaceViewport?
            var latestViewport: PlaceViewport?
            var latestViewportCenter: RodiCoordinate?
            var pendingInitialSearchOrigin: RodiCoordinate?
            var requestOrigin: RodiCoordinate?
            var nextCursor: String?
            var hasNext = false
            var totalCount: Int?
            var isInitialLoading = false
            var isNextPageLoading = false
            var isManualResearchLoading = false
            var shouldAutoExpandAfterResearch = false
            var errorMessage: String?
            var needsResearch = false
            var requestRevision = 0
            var isAdministrativeAreaSearchResults = false
        }

        var bottomSheetState: HomeBottomSheetState = .collapsed
        var sheetHeight: CGFloat = 0
        var selectedItem: RodiCourseItem?
        var selectedRouteOverlay: RodiRouteOverlay?
        var isRouteLoading = false
        var routeStatusMessage: String?
        var selectedPlaceID: Int?
        var placeDetail: PlaceDetail?
        var isPlaceDetailLoading = false
        var isBookmarkUpdating = false
        var placeList = PlaceListState()
        var filter = FilterState()
    }

    enum Action {
        case sheet(SheetAction)
        case selection(SelectionAction)
        case placeList(PlaceListAction)
        case filter(FilterAction)
        case delegate(Delegate)
    }

    enum SheetAction {
        case present(mediumHeight: CGFloat)
        case dismiss
        case expand(availableHeight: CGFloat)
        case collapse(mediumHeight: CGFloat)
        case resetToMedium(mediumHeight: CGFloat)
    }

    enum SelectionAction {
        case clear
        case selectItem(RodiCourseItem, mediumHeight: CGFloat)
        case selectMapItem(RodiCourseItem, mediumHeight: CGFloat)
        case selectPlaceID(Int, mediumHeight: CGFloat)
        case detailLoaded(PlaceDetail)
        case detailAuthenticationRequired(placeID: Int)
        case detailFailed(placeID: Int, message: String)
        case toggleBookmark
        case bookmarkUpdated(placeID: Int, isBookmarked: Bool)
        case bookmarkFailed(placeID: Int, previousDetail: PlaceDetail, message: String)
        case roadRouteLoaded(courseID: Int, path: [RodiCoordinate])
        case roadRouteFailed(courseID: Int, message: String?)
    }

    enum PlaceListAction {
        case viewportChanged(viewport: PlaceViewport, center: RodiCoordinate, isUserInitiated: Bool)
        case prepareInitialSearch(origin: RodiCoordinate)
        case reloadCurrentViewport(origin: RodiCoordinate?)
        case reloadAfterFilter
        case showAdministrativeAreaSearchResults([PlaceListItem])
        case clearAdministrativeAreaSearchResults
        case loadNextPage
        case pageLoaded(page: PlaceCursorPage, viewport: PlaceViewport, revision: Int, isAppending: Bool, isManualResearch: Bool)
        case pageFailed(message: String, revision: Int, isAppending: Bool, isManualResearch: Bool)
        case consumeAutoExpandAfterResearch
    }

    enum FilterAction {
        case present(mediumHeight: CGFloat)
        case dismiss
        case selectCategory(HomePracticeCategory)
        case toggleType(PlacePracticeType)
        case selectAll
        case reset
        case apply
        case applied(HomePracticeFilterSelection)
        case authenticationRequired
        case failed(String)
    }

    enum Delegate {
        case focusMapOnParking(RodiCoordinate)
        case showSnackbar(String)
        case requestAuthentication
    }

    let placeRepository: PlaceRepository
    let memberRepository: MemberRepository
    let filterStore: HomePracticeFilterStore
    let hasActiveSession: () -> Bool

    init(
        placeRepository: PlaceRepository,
        memberRepository: MemberRepository = AuthDependencyContainer.shared.memberRepository,
        filterStore: HomePracticeFilterStore = HomePracticeFilterStore(),
        hasActiveSession: @escaping () -> Bool
    ) {
        self.placeRepository = placeRepository
        self.memberRepository = memberRepository
        self.filterStore = filterStore
        self.hasActiveSession = hasActiveSession
    }

    func reduce(
        _ state: inout State,
        with action: Action
    ) -> Effect<Action> {
        switch action {
        case .sheet(let action):
            return reduceSheet(action, state: &state)

        case .selection(let action):
            return reduceSelection(action, state: &state)

        case .placeList(let action):
            return reducePlaceList(action, state: &state)

        case .filter(let action):
            return reduceFilter(action, state: &state)

        case .delegate:
            return .none
        }
    }

    private func reduceFilter(
        _ action: FilterAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .present(let mediumHeight):
            guard hasActiveSession() else {
                return delegateEffect(.requestAuthentication)
            }
            state.bottomSheetState = .medium
            state.sheetHeight = mediumHeight
            state.filter.draftSelection = state.filter.appliedSelection
            state.filter.isPresented = true

        case .dismiss:
            state.filter.isPresented = false
            state.filter.isApplying = false
            state.filter.draftSelection = state.filter.appliedSelection

        case .selectCategory(let category):
            guard !state.filter.isApplying else { return .none }
            state.filter.draftSelection.selectCategory(category)

        case .toggleType(let type):
            guard !state.filter.isApplying else { return .none }
            state.filter.draftSelection.toggleType(type)

        case .selectAll:
            guard !state.filter.isApplying else { return .none }
            state.filter.draftSelection.selectAll()

        case .reset:
            guard !state.filter.isApplying else { return .none }
            state.filter.draftSelection = .default

        case .apply:
            guard state.filter.canApply else { return .none }
            state.filter.isApplying = true
            return updateFilterEffect(selection: state.filter.draftSelection)

        case .applied(let selection):
            state.filter.appliedSelection = selection
            state.filter.draftSelection = selection
            state.filter.isApplying = false
            state.filter.isPresented = false
            filterStore.save(selection)
            return .send(.placeList(.reloadAfterFilter))

        case .authenticationRequired:
            state.filter.isApplying = false
            return delegateEffect(.requestAuthentication)

        case .failed(let message):
            state.filter.isApplying = false
            return delegateEffect(.showSnackbar(message))
        }

        return .none
    }

    private func reduceSheet(
        _ action: SheetAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .present(let mediumHeight):
            state.bottomSheetState = .medium
            state.sheetHeight = mediumHeight

        case .dismiss:
            state.bottomSheetState = .collapsed
            state.sheetHeight = 0

        case .expand(let availableHeight):
            guard state.bottomSheetState != .expanded else { return .none }
            state.bottomSheetState = .expanded
            state.sheetHeight = availableHeight

        case .collapse(let mediumHeight):
            guard state.bottomSheetState != .medium else { return .none }
            state.bottomSheetState = .medium
            state.sheetHeight = mediumHeight

        case .resetToMedium(let mediumHeight):
            state.bottomSheetState = .medium
            state.sheetHeight = mediumHeight
        }

        return .none
    }

    private func reduceSelection(
        _ action: SelectionAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case .clear:
            clearSelection(state: &state)
            return .cancel(id: HomeEffectID.routeLoading)

        case .selectItem(let item, let mediumHeight):
            return select(item, mediumHeight: mediumHeight, state: &state)

        case .selectMapItem(let item, let mediumHeight):
            guard hasActiveSession() else {
                return delegateEffect(.requestAuthentication)
            }
            return select(item, mediumHeight: mediumHeight, state: &state)

        case .selectPlaceID(let placeID, let mediumHeight):
            return selectPlaceDetail(placeID: placeID, mediumHeight: mediumHeight, state: &state)

        case .detailLoaded(let detail):
            guard state.selectedPlaceID == detail.id else { return .none }

            let item = RodiCourseItem(placeDetail: detail)
            state.selectedItem = item
            state.placeDetail = detail
            state.isPlaceDetailLoading = false
            state.isBookmarkUpdating = false
            return configureRoute(for: item, state: &state)

        case .detailAuthenticationRequired(let placeID):
            guard state.selectedPlaceID == placeID else { return .none }
            clearSelection(state: &state)
            return delegateEffect(.requestAuthentication)

        case .detailFailed(let placeID, let message):
            guard state.selectedPlaceID == placeID else { return .none }
            clearSelection(state: &state)
            return delegateEffect(.showSnackbar(message))

        case .toggleBookmark:
            guard let detail = state.placeDetail,
                  !state.isBookmarkUpdating
            else {
                return .none
            }

            guard hasActiveSession() else {
                return delegateEffect(.requestAuthentication)
            }

            let isBookmarked = !detail.isBookmarked
            state.placeDetail = detail.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = true
            return updateBookmarkEffect(
                placeID: detail.id,
                isBookmarked: isBookmarked,
                previousDetail: detail
            )

        case .bookmarkUpdated(let placeID, let isBookmarked):
            guard state.placeDetail?.id == placeID else { return .none }
            state.placeDetail = state.placeDetail?.updatingBookmark(isBookmarked: isBookmarked)
            state.isBookmarkUpdating = false
            return delegateEffect(.showSnackbar(isBookmarked ? "북마크를 저장했어요." : "북마크를 해제했어요."))

        case .bookmarkFailed(let placeID, let previousDetail, let message):
            guard state.placeDetail?.id == placeID else { return .none }
            state.placeDetail = previousDetail
            state.isBookmarkUpdating = false
            return delegateEffect(.showSnackbar(message))

        case .roadRouteLoaded(let courseID, let path):
            guard state.selectedItem?.id == courseID,
                  let selectedRouteOverlay = state.selectedRouteOverlay
            else {
                return .none
            }
            state.selectedRouteOverlay = RodiRouteOverlay(
                courseID: courseID,
                points: selectedRouteOverlay.points,
                path: path,
                isRoadRoute: true
            )
            state.isRouteLoading = false
            state.routeStatusMessage = nil

        case .roadRouteFailed(let courseID, let message):
            guard state.selectedItem?.id == courseID else { return .none }
            state.isRouteLoading = false
            state.routeStatusMessage = message
        }

        return .none
    }

    private func reducePlaceList(
        _ action: PlaceListAction,
        state: inout State
    ) -> Effect<Action> {
        switch action {
        case let .viewportChanged(viewport, center, isUserInitiated):
            let previousViewport = state.placeList.latestViewport
            state.placeList.latestViewport = viewport
            state.placeList.latestViewportCenter = center

            if state.placeList.isManualResearchLoading, previousViewport != viewport {
                state.placeList.requestRevision += 1
                state.placeList.isInitialLoading = false
                state.placeList.isManualResearchLoading = false
                state.placeList.needsResearch = true
                return .cancel(id: HomeEffectID.placeListLoading)
            }

            if isUserInitiated {
                let hadInFlightRequest = state.placeList.isInitialLoading || state.placeList.isNextPageLoading
                if hadInFlightRequest {
                    state.placeList.requestRevision += 1
                    state.placeList.isInitialLoading = false
                    state.placeList.isNextPageLoading = false
                    state.placeList.isManualResearchLoading = false
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
                    state: &state,
                    isManualResearch: false
                )
            }

        case .prepareInitialSearch(let origin):
            guard state.placeList.activeViewport == nil else { return .none }
            state.placeList.pendingInitialSearchOrigin = origin

            if let viewport = state.placeList.latestViewport,
               let center = state.placeList.latestViewportCenter,
               center.distanceKilometers(to: origin) <= 0.5 {
                return .run { send in
                    await send(.placeList(.viewportChanged(
                        viewport: viewport,
                        center: center,
                        isUserInitiated: false
                    )))
                }
            }

        case .reloadCurrentViewport(let origin):
            guard let viewport = state.placeList.latestViewport,
                  let center = state.placeList.latestViewportCenter,
                  !state.placeList.isInitialLoading,
                  !state.placeList.isNextPageLoading
            else {
                return .none
            }

            return loadFirstPage(
                viewport: viewport,
                origin: origin ?? center,
                state: &state,
                isManualResearch: true
            )

        case .reloadAfterFilter:
            guard let viewport = state.placeList.latestViewport,
                  let origin = state.placeList.requestOrigin ?? state.placeList.latestViewportCenter,
                  !state.placeList.isInitialLoading,
                  !state.placeList.isNextPageLoading
            else {
                return .none
            }

            return loadFirstPage(
                viewport: viewport,
                origin: origin,
                state: &state,
                isManualResearch: false
            )

        case .showAdministrativeAreaSearchResults(let items):
            state.placeList.requestRevision += 1
            state.placeList.items = uniqueItems(items)
            state.placeList.nextCursor = nil
            state.placeList.hasNext = false
            state.placeList.totalCount = state.placeList.items.count
            state.placeList.isInitialLoading = false
            state.placeList.isNextPageLoading = false
            state.placeList.isManualResearchLoading = false
            state.placeList.shouldAutoExpandAfterResearch = false
            state.placeList.errorMessage = nil
            state.placeList.needsResearch = false
            state.placeList.isAdministrativeAreaSearchResults = true
            return .cancel(id: HomeEffectID.placeListLoading)

        case .clearAdministrativeAreaSearchResults:
            guard state.placeList.isAdministrativeAreaSearchResults else { return .none }
            state.placeList.requestRevision += 1
            state.placeList.items = []
            state.placeList.nextCursor = nil
            state.placeList.hasNext = false
            state.placeList.totalCount = nil
            state.placeList.isInitialLoading = false
            state.placeList.isNextPageLoading = false
            state.placeList.isManualResearchLoading = false
            state.placeList.errorMessage = nil
            state.placeList.needsResearch = state.placeList.latestViewport != nil
            state.placeList.isAdministrativeAreaSearchResults = false
            return .cancel(id: HomeEffectID.placeListLoading)

        case .loadNextPage:
            guard !state.placeList.needsResearch,
                  !state.placeList.isAdministrativeAreaSearchResults,
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
                isAppending: true,
                isManualResearch: false
            )

        case let .pageLoaded(page, viewport, revision, isAppending, isManualResearch):
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
            state.placeList.isManualResearchLoading = false
            state.placeList.errorMessage = nil
            state.placeList.isAdministrativeAreaSearchResults = false
            state.placeList.shouldAutoExpandAfterResearch = isManualResearch && !isAppending

        case let .pageFailed(message, revision, isAppending, isManualResearch):
            guard revision == state.placeList.requestRevision else { return .none }
            state.placeList.isInitialLoading = false
            state.placeList.isNextPageLoading = false
            state.placeList.isManualResearchLoading = false
            state.placeList.errorMessage = message
            if !isAppending {
                state.placeList.needsResearch = true
            }
            if isManualResearch {
                return delegateEffect(.showSnackbar(message))
            }

        case .consumeAutoExpandAfterResearch:
            state.placeList.shouldAutoExpandAfterResearch = false
        }

        return .none
    }

    private func select(
        _ item: RodiCourseItem,
        mediumHeight: CGFloat,
        state: inout State
    ) -> Effect<Action> {
        state.bottomSheetState = .medium
        state.sheetHeight = mediumHeight
        state.selectedItem = item
        state.routeStatusMessage = nil
        state.selectedRouteOverlay = nil
        state.isRouteLoading = false
        state.selectedPlaceID = item.id
        state.placeDetail = nil
        state.isPlaceDetailLoading = true
        state.isBookmarkUpdating = false
        return loadPlaceDetailEffect(placeID: item.id)
    }

    private func selectPlaceDetail(
        placeID: Int,
        mediumHeight: CGFloat,
        state: inout State
    ) -> Effect<Action> {
        state.bottomSheetState = .medium
        state.sheetHeight = mediumHeight
        state.selectedItem = nil
        state.routeStatusMessage = nil
        state.selectedRouteOverlay = nil
        state.isRouteLoading = false
        state.selectedPlaceID = placeID
        state.placeDetail = nil
        state.isPlaceDetailLoading = true
        state.isBookmarkUpdating = false
        return loadPlaceDetailEffect(placeID: placeID)
    }

    private func clearSelection(state: inout State) {
        state.selectedItem = nil
        state.selectedRouteOverlay = nil
        state.isRouteLoading = false
        state.routeStatusMessage = nil
        state.selectedPlaceID = nil
        state.placeDetail = nil
        state.isPlaceDetailLoading = false
        state.isBookmarkUpdating = false
    }

    private func configureRoute(
        for item: RodiCourseItem,
        state: inout State
    ) -> Effect<Action> {
        state.routeStatusMessage = nil

        switch item.type {
        case .course:
            let points = item.routeOverlayPoints
            guard points.count >= 2 else {
                state.selectedRouteOverlay = nil
                state.routeStatusMessage = "경로 좌표가 아직 준비되지 않았어요."
                state.isRouteLoading = false
                return .cancel(id: HomeEffectID.routeLoading)
            }

            state.selectedRouteOverlay = RodiRouteOverlay(
                courseID: item.id,
                points: points,
                path: points.map(\.coordinate),
                isRoadRoute: false
            )
            state.isRouteLoading = true
            return loadRoadRouteEffect(courseID: item.id, points: points)

        case .parking:
            state.selectedRouteOverlay = nil
            state.isRouteLoading = false
            return delegateEffect(.focusMapOnParking(item.coordinate))
        }
    }

    private func loadFirstPage(
        viewport: PlaceViewport,
        origin: RodiCoordinate,
        state: inout State,
        isManualResearch: Bool
    ) -> Effect<Action> {
        state.placeList.requestRevision += 1
        state.placeList.isInitialLoading = true
        state.placeList.isNextPageLoading = false
        state.placeList.isManualResearchLoading = isManualResearch
        state.placeList.shouldAutoExpandAfterResearch = false
        state.placeList.errorMessage = nil
        state.placeList.requestOrigin = origin
        state.placeList.nextCursor = nil
        state.placeList.hasNext = false
        state.placeList.isAdministrativeAreaSearchResults = false

        return loadPageEffect(
            viewport: viewport,
            origin: origin,
            cursor: nil,
            revision: state.placeList.requestRevision,
            isAppending: false,
            isManualResearch: isManualResearch
        )
    }

    private func uniqueItems(_ items: [PlaceListItem]) -> [PlaceListItem] {
        var seen = Set<Int>()
        return items.filter { seen.insert($0.id).inserted }
    }

    private func loadPageEffect(
        viewport: PlaceViewport,
        origin: RodiCoordinate,
        cursor: String?,
        revision: Int,
        isAppending: Bool,
        isManualResearch: Bool
    ) -> Effect<Action> {
        let repository = placeRepository
        let access: PlaceListAccess = hasActiveSession() ? .member : .public
        let query = PlaceListQuery(
            viewport: viewport,
            currentLatitude: origin.latitude,
            currentLongitude: origin.longitude,
            size: 20,
            cursor: cursor
        )

        return .run { send in
            do {
                if isManualResearch {
                    try await Task.sleep(for: .milliseconds(350))
                }
                let page = try await repository.fetchPlaces(query: query, access: access)
                await send(.placeList(.pageLoaded(
                    page: page,
                    viewport: viewport,
                    revision: revision,
                    isAppending: isAppending,
                    isManualResearch: isManualResearch
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
                await send(.placeList(.pageFailed(
                    message: "추천 목록을 불러오지 못했어요.",
                    revision: revision,
                    isAppending: isAppending,
                    isManualResearch: isManualResearch
                )))
            }
        }
        .cancelTask(id: HomeEffectID.placeListLoading)
    }

    private func updateFilterEffect(
        selection: HomePracticeFilterSelection
    ) -> Effect<Action> {
        let repository = memberRepository
        return .run { send in
            do {
                try await repository.updatePlaceFilterTags(selection.filterTags)
                await send(.filter(.applied(selection)))
            } catch is CancellationError {
                return
            } catch {
                RodiLogger.warning("Home practice filter update failed. error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.filter(.authenticationRequired))
                    return
                }
                await send(.filter(.failed("필터를 적용하지 못했어요. 다시 시도해 주세요.")))
            }
        }
        .cancelTask(id: HomeEffectID.practiceFilterUpdating)
    }

    private func loadPlaceDetailEffect(placeID: Int) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                let detail = try await repository.fetchPlaceDetail(id: placeID)
                await send(.selection(.detailLoaded(detail)))
                RodiLogger.info("Home place detail loaded placeID=\(placeID), type=\(detail.type.rawValue)")
            } catch is CancellationError {
                RodiLogger.info("Home place detail request cancelled placeID=\(placeID)")
            } catch {
                RodiLogger.warning("Home place detail request failed placeID=\(placeID), error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.selection(.detailAuthenticationRequired(placeID: placeID)))
                    return
                }
                await send(.selection(.detailFailed(
                    placeID: placeID,
                    message: "장소 상세 정보를 불러오지 못했어요."
                )))
            }
        }
        .cancelTask(id: HomeEffectID.placeDetailLoading)
    }

    private func updateBookmarkEffect(
        placeID: Int,
        isBookmarked: Bool,
        previousDetail: PlaceDetail
    ) -> Effect<Action> {
        let repository = placeRepository
        return .run { send in
            do {
                if isBookmarked {
                    try await repository.bookmark(placeID: placeID)
                } else {
                    try await repository.unbookmark(placeID: placeID)
                }
                await send(.selection(.bookmarkUpdated(placeID: placeID, isBookmarked: isBookmarked)))
            } catch is CancellationError {
                RodiLogger.info("Home bookmark request cancelled placeID=\(placeID)")
            } catch {
                RodiLogger.warning("Home bookmark update failed placeID=\(placeID), error=\(error.localizedDescription)")
                if requiresAuthentication(error) {
                    await send(.delegate(.requestAuthentication))
                    return
                }
                await send(.selection(.bookmarkFailed(
                    placeID: placeID,
                    previousDetail: previousDetail,
                    message: bookmarkFailureMessage(for: error, isBookmarked: isBookmarked)
                )))
            }
        }
        .cancelTask(id: HomeEffectID.bookmarkUpdating)
    }

    private func loadRoadRouteEffect(
        courseID: Int,
        points: [RodiRouteOverlayPoint]
    ) -> Effect<Action> {
        .run { send in
            do {
                let path = try await KakaoDirectionsService().fetchRoute(points: points)
                await send(.selection(.roadRouteLoaded(courseID: courseID, path: path)))
                RodiLogger.info("Road route loaded courseID=\(courseID), vertexCount=\(path.count)")
            } catch KakaoDirectionsError.missingAPIKey {
                await send(.selection(.roadRouteFailed(
                    courseID: courseID,
                    message: KakaoDirectionsError.missingAPIKey.fallbackMessage
                )))
            } catch let error as KakaoDirectionsError {
                await send(.selection(.roadRouteFailed(courseID: courseID, message: error.fallbackMessage)))
            } catch is CancellationError {
                RodiLogger.info("Kakao directions request cancelled courseID=\(courseID)")
            } catch {
                await send(.selection(.roadRouteFailed(
                    courseID: courseID,
                    message: "도로 경로를 불러오지 못해 대체 경로로 표시 중이에요."
                )))
            }
        }
        .cancelTask(id: HomeEffectID.routeLoading)
    }

    private func delegateEffect(_ delegate: Delegate) -> Effect<Action> {
        .run { send in
            await send(.delegate(delegate))
        }
    }

    private func requiresAuthentication(_ error: Error) -> Bool {
        guard let networkError = error as? NetworkError else { return false }
        return switch networkError {
        case .refreshFailGoRoot, .httpStatusCode(401):
            true
        case .apiError(let code, _, _):
            code.hasPrefix("AUTH_401") || code == "AUTH_400_1"
        default:
            false
        }
    }

    private func bookmarkFailureMessage(for error: Error, isBookmarked: Bool) -> String {
        let action = isBookmarked ? "저장" : "해제"
        guard let networkError = error as? NetworkError else {
            return "북마크를 \(action)하지 못했어요."
        }

        switch networkError {
        case .networkUnavailable, .timeOut:
            return "인터넷 연결을 확인한 뒤 다시 시도해주세요."
        case .httpStatusCode(let statusCode) where statusCode >= 500:
            return "서버 오류로 북마크를 \(action)하지 못했어요."
        case .apiError(_, let message, _) where !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
            return message
        case .refreshFailGoRoot, .httpStatusCode(401):
            return "로그인이 만료됐어요. 다시 로그인해주세요."
        default:
            return "북마크를 \(action)하지 못했어요."
        }
    }
}
