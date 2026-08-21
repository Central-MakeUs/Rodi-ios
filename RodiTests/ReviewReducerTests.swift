import XCTest
@testable import Rodi

@MainActor
final class ReviewReducerTests: XCTestCase {

    func testDirectWritingRequestStartsFirstWritingPage() {
        let reducer = makeReducer()
        var state = ReviewReducer.State()

        _ = reducer.reduce(
            &state,
            with: .directWritingRequested(.init(placeID: 1, placeName: "연습 코스"))
        )

        XCTAssertEqual(state.route, .writing)
        XCTAssertEqual(state.writing.page, .first)
        XCTAssertEqual(state.writing.target?.placeID, 1)
    }

    func testWritingRequiresSelectionsButNotOptionalCaution() {
        let reducer = makeWritingReducer()
        var state = ReviewWritingReducer.State()
        let request = ReviewWriteRequest(placeID: 1, placeName: "연습 코스")

        _ = reducer.reduce(&state, with: .start(request))
        _ = reducer.reduce(&state, with: .recommendationSelected(true))
        _ = reducer.reduce(&state, with: .difficultySelected(.easy))
        _ = reducer.reduce(&state, with: .congestionSelected(.quiet))
        _ = reducer.reduce(&state, with: .nextTapped)

        XCTAssertEqual(state.page, .second)
    }

    func testWritingIgnoresResponseFromPreviousFlow() {
        let reducer = makeWritingReducer()
        var state = ReviewWritingReducer.State()
        let firstRequest = ReviewWriteRequest(placeID: 1, placeName: "첫 번째")
        let oldFlowID = state.flowID

        _ = reducer.reduce(&state, with: .start(firstRequest))
        let staleFlowID = state.flowID
        _ = reducer.reduce(&state, with: .reset)
        _ = reducer.reduce(
            &state,
            with: .start(.init(placeID: 2, placeName: "두 번째"))
        )

        _ = reducer.reduce(
            &state,
            with: .submissionCompleted(.success(()), flowID: staleFlowID, requestID: 1)
        )

        XCTAssertNotEqual(oldFlowID, state.flowID)
        XCTAssertNotEqual(staleFlowID, state.flowID)
        XCTAssertFalse(state.isCompletionPresented)
    }

    private func makeReducer() -> ReviewReducer {
        .init(
            promptService: PromptServiceStub(),
            writingService: WritingServiceStub(),
            skipReasonService: SkipReasonServiceStub()
        )
    }

    private func makeWritingReducer() -> ReviewWritingReducer {
        .init(service: WritingServiceStub())
    }
}

private struct PromptServiceStub: ReviewPromptServicing {
    func prepareTarget(placeID: Int) async throws -> ReviewTarget {
        .init(placeID: placeID, practiceID: 1, placeName: "연습 코스")
    }

    func recordVisit(practiceID: Int) async throws {}
}

private struct WritingServiceStub: ReviewWritingServicing {
    func fetchReviewDetail(reviewID: Int) async throws -> ReviewDetail { fatalError() }
    func createReview(placeID: Int, submission: PlaceReviewSubmission) async throws {}
    func updateReview(reviewID: Int, submission: PlaceReviewSubmission) async throws {}
}

private struct SkipReasonServiceStub: ReviewSkipReasonServicing {
    func fetchForm() async throws -> PracticeSkipReasonForm {
        .init(
            questionID: nil,
            type: nil,
            title: nil,
            description: nil,
            isRequired: false,
            options: []
        )
    }

    func submit(practiceID: Int, reasonCode: String, detail: String?) async throws {}
}
