import XCTest
@testable import Rodi

@MainActor
final class CourseRegistrationMapSelectionReducerTests: XCTestCase {
    func testPreviousAddressResponseDoesNotReplaceNewCandidate() {
        let reducer = CourseRegistrationMapSelectionReducer()
        var state = CourseRegistrationMapSelectionReducer.State(isCourseTutorialCompleted: true)
        let previousCoordinate = RodiCoordinate(latitude: 37.5, longitude: 127.0)
        let currentCoordinate = RodiCoordinate(latitude: 37.6, longitude: 127.1)

        _ = reducer.reduce(&state, with: .candidateAddressRequested(.start, previousCoordinate, debounce: false))
        let previousRequest = CourseRegistrationMapSelectionReducer.AddressRequest(
            revision: state.map.addressRequestRevision,
            target: .start,
            coordinate: previousCoordinate
        )

        _ = reducer.reduce(&state, with: .candidateAddressRequested(.start, currentCoordinate, debounce: false))
        let currentRequest = CourseRegistrationMapSelectionReducer.AddressRequest(
            revision: state.map.addressRequestRevision,
            target: .start,
            coordinate: currentCoordinate
        )

        _ = reducer.reduce(&state, with: .reverseGeocodingFinished(previousRequest, .success("이전 주소")))
        XCTAssertNil(state.map.candidateAddress)

        _ = reducer.reduce(&state, with: .reverseGeocodingFinished(currentRequest, .success("최신 주소")))
        XCTAssertEqual(state.map.candidateAddress, "최신 주소")
        XCTAssertEqual(state.map.candidateCoordinate, currentCoordinate)
    }

    func testAddressResponseForPreviousSelectionTargetIsIgnored() {
        let reducer = CourseRegistrationMapSelectionReducer()
        var state = CourseRegistrationMapSelectionReducer.State(isCourseTutorialCompleted: true)
        let startCoordinate = RodiCoordinate(latitude: 37.5, longitude: 127.0)
        let destinationCoordinate = RodiCoordinate(latitude: 37.6, longitude: 127.1)

        _ = reducer.reduce(&state, with: .candidateAddressRequested(.start, startCoordinate, debounce: false))
        let startRequest = CourseRegistrationMapSelectionReducer.AddressRequest(
            revision: state.map.addressRequestRevision,
            target: .start,
            coordinate: startCoordinate
        )

        state.map.selectionTarget = .destination
        _ = reducer.reduce(&state, with: .candidateAddressRequested(.destination, destinationCoordinate, debounce: false))

        _ = reducer.reduce(&state, with: .reverseGeocodingFinished(startRequest, .success("출발지 주소")))

        XCTAssertNil(state.map.candidateAddress)
        XCTAssertEqual(state.map.candidateCoordinate, destinationCoordinate)
        XCTAssertTrue(state.map.isAddressResolving)
    }
}
