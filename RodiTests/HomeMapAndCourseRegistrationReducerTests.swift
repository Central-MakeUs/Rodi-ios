import XCTest
@testable import Rodi

@MainActor
final class HomeMapAndCourseRegistrationReducerTests: XCTestCase {
    private let clusterViewport = PlaceViewport(
        southWestLatitude: 37, southWestLongitude: 126,
        northEastLatitude: 38, northEastLongitude: 127
    )

    func testClusterAndSortTagRequestContracts() throws {
        let filtered = PlaceAPI.clusters(PlaceMapper.clusterQuery(from: .init(
            viewport: clusterViewport, practiceTypes: [.parking]
        )))
        XCTAssertEqual(filtered.path, "/api/v1/places/clusters")
        XCTAssertFalse(filtered.requiresAuthentication)
        XCTAssertEqual(filtered.parameters?["practiceTypes"] as? String, "PARKING")
        let unfiltered = PlaceAPI.clusters(PlaceMapper.clusterQuery(from: .init(
            viewport: clusterViewport, practiceTypes: []
        )))
        XCTAssertNil(unfiltered.parameters?["practiceTypes"])

        for tags: [PlacePracticeType] in [[.parking], []] {
            let api = MemberAPI.updateSortTags(MemberMapper.sortTagsRequest(from: tags))
            XCTAssertEqual(api.path, "/api/v1/members/me/sort-tags")
            XCTAssertEqual(api.method.rawValue, "PUT")
            XCTAssertTrue(api.requiresAuthentication)
            let json = try JSONDecoder().decode([String: [String]].self, from: XCTUnwrap(api.body))
            XCTAssertEqual(json, ["sortTags": tags.map(\.rawValue)])
        }
    }

    func testServerMarkerLevelsBoundsAndStaleResponses() {
        let reducer = HomeMapReducer(dependencies: .init(
            placeRepository: HomeMapPlaceRepositoryStub(), hasActiveSession: { false }
        ))
        var state = HomeMapState()
        let result = PlaceClusterResult(
            places: [.init(id: 7, type: .parking, name: "주차장", address: "서울", latitude: 37.5, longitude: 126.5)],
            levels: [
                .init(minLongitudeSpan: 0, maxLongitudeSpan: 1, clusters: [], placeIDs: [7]),
                .init(minLongitudeSpan: 1, maxLongitudeSpan: nil, clusters: [
                    .init(latitude: 37.5, longitude: 126.5, count: 2, bounds: clusterViewport)
                ], placeIDs: [])
            ]
        )
        XCTAssertEqual(result.levelIndex(for: 0.999), 0)
        XCTAssertEqual(result.levelIndex(for: 1), 1)
        XCTAssertEqual(result.levelIndex(for: 100), 1)
        let query = PlaceClusterQuery(viewport: clusterViewport, practiceTypes: [.parking])
        _ = reducer.reduce(&state, with: .clusterQueryRequested(query, listRevision: 1))
        _ = reducer.reduce(&state, with: .clusterQueryRequested(query, listRevision: 2))
        _ = reducer.reduce(&state, with: .serviceOutput(.clustersLoaded(result, revision: 1)))
        XCTAssertTrue(state.markers.isEmpty)
        _ = reducer.reduce(&state, with: .serviceOutput(.clustersLoaded(result, revision: 2)))
        XCTAssertEqual(state.markers.map(\.kind), [.cluster])
        guard let markerID = state.markers.first?.id else { return XCTFail("서버 클러스터가 필요합니다.") }
        _ = reducer.reduce(&state, with: .markerTapped(markerID))
        guard case let .cluster(coordinates) = state.cameraFocus else { return XCTFail("범위 맞춤이 필요합니다.") }
        XCTAssertEqual(coordinates, [
            .init(latitude: 37, longitude: 126), .init(latitude: 38, longitude: 127)
        ])
        let closer = PlaceViewport(southWestLatitude: 37.4, southWestLongitude: 126.4,
                                   northEastLatitude: 37.6, northEastLongitude: 126.6)
        _ = reducer.reduce(&state, with: .viewportChanged(center: coordinates[0], zoomLevel: 12,
                                                         viewport: closer, isUserInitiated: true))
        XCTAssertEqual(state.clusterRequestRevision, 2)
        XCTAssertEqual(state.markers.map(\.id), ["parking-7"])
        _ = reducer.reduce(&state, with: .clusterQueryRequested(query, listRevision: 3))
        _ = reducer.reduce(&state, with: .serviceOutput(.clusterLoadFailed(revision: 3)))
        XCTAssertEqual(state.markers.map(\.id), ["parking-7"])
        XCTAssertTrue(state.isResearchButtonVisible)
    }

    func testFirstValidViewportUsesSameFilterForMapAndList() async {
        let reducer = RecommendListBottomSheetReducer(
            placeRepository: HomeMapPlaceRepositoryStub(), hasActiveSession: { false }
        )
        var state = RecommendListBottomSheetReducer.State()
        state.practiceTypes = [.parking]
        let center = RodiCoordinate(latitude: 37.5, longitude: 126.5)
        let invalid = PlaceViewport(southWestLatitude: 38, southWestLongitude: 126,
                                    northEastLatitude: 37, northEastLongitude: 127)
        _ = reducer.reduce(&state, with: .viewportChanged(viewport: invalid, center: center, isUserInitiated: false))
        XCTAssertEqual(state.requestRevision, 0)
        let effect = reducer.reduce(&state, with: .viewportChanged(
            viewport: clusterViewport, center: center, isUserInitiated: false
        ))
        XCTAssertEqual(state.requestedPracticeTypes, [.parking])
        guard case let .run(_, task) = effect.caseOf else { return XCTFail("첫 페이지 요청이 필요합니다.") }
        var query: PlaceClusterQuery?
        await task { action in
            if case let .delegate(.firstPageRequested(snapshot, _)) = action { query = snapshot }
        }
        XCTAssertEqual(query, .init(viewport: clusterViewport, practiceTypes: [.parking]))
    }

    func testRegionReloadUsesSettledViewportRatherThanPreviousViewport() async {
        let reducer = RecommendListBottomSheetReducer(
            placeRepository: HomeMapPlaceRepositoryStub(), hasActiveSession: { false }
        )
        var state = RecommendListBottomSheetReducer.State()
        let origin = RodiCoordinate(latitude: 37.5, longitude: 126.5)
        state.latestViewport = .init(southWestLatitude: 34, southWestLongitude: 128,
                                     northEastLatitude: 35, northEastLongitude: 129)
        _ = reducer.reduce(&state, with: .regionViewportReloadStarted(origin: origin))
        XCTAssertEqual(state.firstPageRevision, 0)
        let effect = reducer.reduce(&state, with: .reloadAfterRegionViewport(
            viewport: clusterViewport, origin: origin
        ))
        guard case let .run(_, task) = effect.caseOf else { return XCTFail("이동 완료 후 조회가 필요합니다.") }
        var query: PlaceClusterQuery?
        await task { action in
            if case let .delegate(.firstPageRequested(snapshot, _)) = action { query = snapshot }
        }
        XCTAssertEqual(query?.viewport, clusterViewport)
        guard case .none = reducer.reduce(&state, with: .reloadAfterRegionViewport(
            viewport: clusterViewport, origin: origin
        )).caseOf else { return XCTFail("같은 이동 완료 신호를 중복 처리하면 안 됩니다.") }
    }

    func testUserViewportChangeDuringInitialLoadingShowsResearchButtonBeforeCancelling() async {
        let reducer = RecommendListBottomSheetReducer(
            placeRepository: HomeMapPlaceRepositoryStub(),
            hasActiveSession: { false }
        )
        var state = RecommendListBottomSheetReducer.State()
        state.activeViewport = PlaceViewport(
            southWestLatitude: 37.4,
            southWestLongitude: 126.9,
            northEastLatitude: 37.6,
            northEastLongitude: 127.1
        )
        state.isInitialLoading = true

        let effect = reducer.reduce(
            &state,
            with: .viewportChanged(
                viewport: PlaceViewport(
                    southWestLatitude: 37.5,
                    southWestLongitude: 127.0,
                    northEastLatitude: 37.7,
                    northEastLongitude: 127.2
                ),
                center: .init(latitude: 37.6, longitude: 127.1),
                isUserInitiated: true
            )
        )

        XCTAssertTrue(state.needsResearch)
        XCTAssertFalse(state.isInitialLoading)
        guard case let .run(_, task) = effect.caseOf else {
            return XCTFail("로딩 중 지도 이동은 버튼 상태 전달 뒤 기존 목록 요청을 취소해야 합니다.")
        }

        var emittedActions: [RecommendListBottomSheetReducer.Action] = []
        await task { action in
            emittedActions.append(action)
        }

        XCTAssertEqual(emittedActions.count, 2)
        guard emittedActions.count == 2 else { return }
        guard case let .delegate(.displayStateChanged(_, showsResearchButton)) = emittedActions[0] else {
            return XCTFail("먼저 재검색 버튼 표시 상태를 전달해야 합니다.")
        }
        XCTAssertTrue(showsResearchButton)
        guard case .placeListLoadingCancellationRequested = emittedActions[1] else {
            return XCTFail("표시 상태 전달 뒤 기존 목록 요청을 취소해야 합니다.")
        }
    }

    func testGuestPlaceMarkerTapRequestsAuthenticationWithoutChangingMapSelection() {
        let reducer = HomeMapReducer(
            dependencies: .init(
                placeRepository: HomeMapPlaceRepositoryStub(),
                hasActiveSession: { false }
            )
        )
        let place = PlaceCoordinate(
            id: 1,
            type: .course,
            name: "테스트 코스",
            address: "서울",
            latitude: 37.5,
            longitude: 127.0
        )
        let item = RodiCourseItem(placeCoordinate: place)
        let marker = try! XCTUnwrap(item.mapMarker)
        var state = HomeMapState()
        state.markers = [marker]
        state.cameraTarget = .southKoreaCenter
        state.cameraFocus = .koreaOverview
        state.isCurrentLocationButtonActive = true

        let effect = reducer.reduce(&state, with: .markerTapped(marker.id))

        guard case let .send(action) = effect.caseOf,
              case .delegate(.requestAuthentication) = action
        else {
            return XCTFail("비로그인 단일 마커 탭은 인증 요청만 전달해야 합니다.")
        }
        XCTAssertEqual(state.cameraTarget, .southKoreaCenter)
        XCTAssertEqual(state.cameraFocus, .koreaOverview)
        XCTAssertNil(state.selectedMarkerID)
        XCTAssertTrue(state.isCurrentLocationButtonActive)
    }

    func testRegistrationDefaultsToFirstCategoryAndKeepsItClean() {
        let reducer = CourseRegistrationDetailsReducer(courseRepository: CourseRepositoryStub())
        var state = CourseRegistrationDetailsReducer.State()
        let requestID = UUID()
        state.activeRequestID = requestID

        _ = reducer.reduce(&state, with: .formLoaded(requestID, .success(registrationForm)))

        XCTAssertEqual(state.draft.selectedCategoryCodes, ["BASIC"])
        XCTAssertTrue(state.draft.selectedPracticeTypeCodes.isEmpty)
        XCTAssertFalse(state.isDirty)
    }

    func testRegistrationCategorySwitchKeepsPreviousPracticeTypes() {
        let reducer = CourseRegistrationDetailsReducer(courseRepository: CourseRepositoryStub())
        var state = CourseRegistrationDetailsReducer.State()
        let requestID = UUID()
        state.activeRequestID = requestID
        _ = reducer.reduce(&state, with: .formLoaded(requestID, .success(registrationForm)))
        state.draft.selectedPracticeTypeCodes = ["STRAIGHT"]

        _ = reducer.reduce(&state, with: .categoryTapped("URBAN"))

        XCTAssertEqual(state.draft.selectedCategoryCodes, ["URBAN"])
        XCTAssertEqual(state.draft.selectedPracticeTypeCodes, ["STRAIGHT"])
    }

    func testHomeFilterKeepsTypesAcrossCategoryChanges() {
        var selection = HomePracticeFilterSelection()

        selection.selectCategory(.basicDriving)
        selection.toggleType(.straight)
        selection.selectCategory(.urbanBasics)
        selection.toggleType(.intersection)
        selection.selectCategory(.trafficFlow)
        selection.toggleType(.merging)
        selection.selectCategory(.urbanBasics)

        XCTAssertEqual(selection.category, .urbanBasics)
        XCTAssertEqual(selection.filterTags, [.straight, .intersection, .merging])
        XCTAssertTrue(selection.selectedTypes.contains(.intersection))
    }

    func testHomeFilterTappingActiveCategoryHidesPracticeTypes() {
        var selection = HomePracticeFilterSelection()

        selection.selectCategory(.basicDriving)
        selection.toggleType(.straight)
        selection.selectCategory(.basicDriving)

        XCTAssertNil(selection.category)
        XCTAssertFalse(selection.showsPracticeTypeOptions)
        XCTAssertEqual(selection.filterTags, [.straight])
    }

    func testHomeFilterParkingAddsAndRemovesParkingTagWithoutPracticeTypes() {
        var selection = HomePracticeFilterSelection()

        selection.selectCategory(.parking)

        XCTAssertEqual(selection.category, .parking)
        XCTAssertFalse(selection.showsPracticeTypeOptions)
        XCTAssertEqual(selection.filterTags, [.parking])

        selection.selectCategory(.parking)

        XCTAssertNil(selection.category)
        XCTAssertTrue(selection.filterTags.isEmpty)
    }

    func testPinEditingCompletionWithoutConfirmedPlaceDoesNothing() {
        let reducer = CourseRegistrationPinEditingReducer()
        let place = CourseRegistrationSelectedPlace(
            name: "기존 출발지",
            coordinate: .init(latitude: 37.5, longitude: 127.0)
        )
        var state = CourseRegistrationPinEditingReducer.State(target: .start, originalPlace: place)

        let effect = reducer.reduce(&state, with: .completionTapped([]))

        guard case .none = effect.caseOf else {
            return XCTFail("확정 전 완료 요청은 종료나 저장을 시작하면 안 됩니다.")
        }
        XCTAssertFalse(state.isSaving)
        XCTAssertNil(state.temporaryPlace)
    }
}

private extension HomeMapAndCourseRegistrationReducerTests {
    var registrationForm: CourseRegistrationForm {
        .init(
            maxWaypoints: 3,
            sections: .init(
                basicInfo: "기본 정보",
                practiceCategory: "연습유형 카테고리",
                practiceType: "연습유형",
                caution: "주의사항",
                description: "한줄 소개"
            ),
            practiceType: .init(
                maxSelect: 3,
                maxSelectExceededMessage: "최대 선택 수를 초과했어요.",
                categories: [
                    .init(
                        code: "BASIC",
                        label: "기초 주행",
                        order: 1,
                        practiceTypes: [
                            .init(code: "STRAIGHT", label: "직선주행", order: 1),
                            .init(code: "TURN", label: "좌우회전", order: 2)
                        ]
                    ),
                    .init(
                        code: "URBAN",
                        label: "도심 기본",
                        order: 2,
                        practiceTypes: [
                            .init(code: "INTERSECTION", label: "교차로", order: 1),
                            .init(code: "UTURN", label: "유턴", order: 2)
                        ]
                    )
                ]
            ),
            inputs: .init(
                caution: .init(required: false, minLength: nil, maxLength: 100, placeholder: "주의사항"),
                description: .init(required: true, minLength: 10, maxLength: 30, placeholder: "한줄 소개")
            )
        )
    }
}

private struct HomeMapPlaceRepositoryStub: PlaceRepository {
    func fetchClusters(query: PlaceClusterQuery) async throws(NetworkError) -> PlaceClusterResult {
        .init(places: [], levels: [])
    }
    func fetchCoordinates() async throws(NetworkError) -> [PlaceCoordinate] { [] }
    func fetchPlaces(query: PlaceListQuery, access: PlaceListAccess) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func searchPlaces(query: PlaceSearchQuery) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func fetchRelatedSearches(query: PlaceRelatedSearchQuery) async throws(NetworkError) -> PlaceRelatedSearchResult { .init(regions: [], places: .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0)) }
    func fetchBookmarkedPlaces(query: PlaceBookmarkListQuery) async throws(NetworkError) -> PlaceCursorPage { .init(items: [], hasNext: false, nextCursor: nil, totalCount: 0) }
    func fetchPlaceDetail(id: Int) async throws(NetworkError) -> PlaceDetail { fatalError() }
    func bookmark(placeID: Int) async throws(NetworkError) {}
    func unbookmark(placeID: Int) async throws(NetworkError) {}
}

private struct CourseRepositoryStub: CourseRepository {
    func fetchRegistrationForm() async throws(NetworkError) -> CourseRegistrationForm { fatalError() }
    func register(_ submission: CourseRegistrationSubmission) async throws(NetworkError) -> CourseRegistrationResult { fatalError() }
    func fetchMyCourses(query: MyCourseQuery) async throws(NetworkError) -> MyCoursePage { fatalError() }
    func deleteMyCourse(courseID: Int64) async throws(NetworkError) {}
    func fetchReportForm() async throws(NetworkError) -> CourseReportForm { throw .decodingFail }
    func report(courseID: Int64, submission: CourseReportSubmission) async throws(NetworkError) { throw .encodingFail }
}
