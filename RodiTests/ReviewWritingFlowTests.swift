#if DEBUG
import XCTest
@testable import Rodi

@MainActor
final class ReviewWritingFlowTests: XCTestCase {
    private let reducer = ReviewWritingReducer(service: DebugReviewWritingService(), tracksAnalytics: false)
    private let target = ReviewWriteRequest(placeID: 1, placeName: "테스트 코스")

    func testNegativeReviewRequiresIssuesAndValidOtherText() throws {
        var state = loadedState()
        send(.recommendationSelected(false), to: &state)
        send(.nextTapped, to: &state)
        XCTAssertEqual(state.page, .first)
        XCTAssertFalse(state.canProceedToSecondPage)

        send(.courseIssueToggled("ROAD_INFO_MISMATCH"), to: &state)
        send(.courseIssueToggled("OTHER"), to: &state)
        send(.courseIssueDetailChanged("   "), to: &state)
        XCTAssertFalse(state.canProceedToSecondPage)
        send(.courseIssueDetailChanged(String(repeating: "가", count: 31)), to: &state)
        XCTAssertFalse(state.canProceedToSecondPage)
        send(.courseIssueDetailChanged("테스트 사유"), to: &state)
        XCTAssertTrue(state.canProceedToSecondPage)

        send(.nextTapped, to: &state)
        XCTAssertEqual(state.page, .second)
        XCTAssertFalse(state.canSubmit)
        send(.practiceMethodSelected(.solo), to: &state)
        XCTAssertTrue(state.canSubmit)
        let submission = try XCTUnwrap(state.draft.submission(form: state.form))
        XCTAssertEqual(submission.courseIssues, ["ROAD_INFO_MISMATCH", "OTHER"])
        XCTAssertEqual(submission.courseIssueDetail, "테스트 사유")
        XCTAssertNil(submission.difficulty)
        XCTAssertNil(submission.congestion)
        XCTAssertNil(submission.caution)
    }

    func testSwitchingToRecommendedKeepsOriginalEvaluationRequirements() throws {
        var state = loadedState()
        send(.recommendationSelected(false), to: &state)
        send(.courseIssueToggled("OTHER"), to: &state)
        send(.courseIssueDetailChanged("테스트 사유"), to: &state)
        send(.recommendationSelected(true), to: &state)
        XCTAssertTrue(state.draft.courseIssues.isEmpty)
        XCTAssertTrue(state.draft.courseIssueDetail.isEmpty)
        XCTAssertFalse(state.canProceedToSecondPage)
        send(.difficultySelected(.easy), to: &state)
        send(.congestionSelected(.quiet), to: &state)
        send(.nextTapped, to: &state)
        send(.practiceMethodSelected(.accompanied), to: &state)
        let submission = try XCTUnwrap(state.draft.submission(form: state.form))
        XCTAssertEqual(submission.difficulty, .easy)
        XCTAssertEqual(submission.congestion, .quiet)
        XCTAssertNil(submission.courseIssues)
    }

    func testRetryAndDiscardIgnoreOldFormResponses() {
        var state = ReviewWritingReducer.State()
        send(.start(target), to: &state)
        XCTAssertEqual(state.page, .loading)
        let firstRequestID = state.requestID
        send(.formLoaded(.failure("오류"), flowID: state.flowID, requestID: firstRequestID), to: &state)
        XCTAssertEqual(state.page, .loadFailed("오류"))
        send(.retryLoading, to: &state)
        let retryRequestID = state.requestID
        load(requestID: firstRequestID, into: &state)
        XCTAssertEqual(state.page, .loading)
        send(.closeTapped, to: &state)
        send(.discardConfirmed, to: &state)
        load(requestID: retryRequestID, into: &state)
        XCTAssertNil(state.form)
    }

    func testProdLegacyNegativeSubmissionKeepsEvaluationFields() throws {
        var draft = ReviewDraft()
        draft.isRecommended = false
        draft.difficulty = .normal
        draft.congestion = .quiet
        draft.practiceMethod = .solo
        let submission = try XCTUnwrap(draft.submission(form: nil))
        XCTAssertEqual(submission.difficulty, .normal)
        XCTAssertEqual(submission.congestion, .quiet)
        XCTAssertNil(submission.courseIssues)
    }

    private func loadedState() -> ReviewWritingReducer.State {
        var state = ReviewWritingReducer.State()
        send(.start(target), to: &state)
        load(requestID: state.requestID, into: &state)
        return state
    }

    private func load(requestID: Int, into state: inout ReviewWritingReducer.State) {
        let loaded = ReviewWritingReducer.LoadedForm(target: target, form: DebugReviewWritingService.form, detail: nil)
        send(.formLoaded(.success(loaded), flowID: state.flowID, requestID: requestID), to: &state)
    }

    private func send(_ action: ReviewWritingReducer.Action, to state: inout ReviewWritingReducer.State) {
        _ = reducer.reduce(&state, with: action)
    }
}
#endif
