import XCTest
@testable import Rodi

@MainActor
final class HomeMapAndCourseRegistrationReducerTests: XCTestCase {
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
        state.mapItems = [item]
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

    func testRegistrationCategorySwitchClearsPreviousPracticeTypes() {
        let reducer = CourseRegistrationDetailsReducer(courseRepository: CourseRepositoryStub())
        var state = CourseRegistrationDetailsReducer.State()
        let requestID = UUID()
        state.activeRequestID = requestID
        _ = reducer.reduce(&state, with: .formLoaded(requestID, .success(registrationForm)))
        state.draft.selectedPracticeTypeCodes = ["STRAIGHT"]

        _ = reducer.reduce(&state, with: .categoryTapped("URBAN"))

        XCTAssertEqual(state.draft.selectedCategoryCodes, ["URBAN"])
        XCTAssertTrue(state.draft.selectedPracticeTypeCodes.isEmpty)
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
}
