import XCTest
@testable import Rodi

@MainActor
final class CourseReviewReducerTests: XCTestCase {
    func testReportedReviewIsRemovedAndReturnsToOriginalRoute() {
        let reducer = makeReducer()
        let review = makeReview(id: 10, memberID: 100)
        var state = CourseReviewReducer.State(
            placeID: 1,
            route: .report,
            reportReturnRoute: .preview,
            pages: [.current: .init(items: [review])]
        )

        _ = reducer.reduce(
            &state,
            with: .report(.delegate(.submitted(reviewID: review.id)))
        )

        XCTAssertEqual(state.route, .preview)
        XCTAssertTrue(state.reportedReviewIDs.contains(review.id))
        XCTAssertTrue(state.pages[.current]?.items.isEmpty == true)
    }

    func testBlockedMemberIsRemovedFromEveryCachedLevel() {
        let reducer = makeReducer()
        let blocked = makeReview(id: 10, memberID: 100)
        let remaining = makeReview(id: 11, memberID: 200)
        var state = CourseReviewReducer.State(
            placeID: 1,
            pages: [
                .current: .init(items: [blocked, remaining]),
                .level(.seed): .init(items: [blocked])
            ]
        )

        _ = reducer.reduce(
            &state,
            with: .block(.delegate(.blocked(memberID: blocked.memberID)))
        )

        XCTAssertTrue(state.blockedMemberIDs.contains(blocked.memberID))
        XCTAssertEqual(state.pages[.current]?.items, [remaining])
        XCTAssertTrue(state.pages[.level(.seed)]?.items.isEmpty == true)
    }

    private func makeReducer() -> CourseReviewReducer {
        .init(repository: ReviewRepositoryStub(), memberRepository: MemberRepositoryStub(), hasActiveSession: { true })
    }

    private func makeReview(id: Int, memberID: Int) -> PlaceReviewItem {
        .init(id: id, memberID: memberID, nickname: "테스터", practiceMethod: .solo, content: "후기", isMine: false, isEditable: false, isHidden: false, isVerifiedVisit: false, createdAt: "2026-08-12")
    }
}

private struct ReviewRepositoryStub: ReviewRepository {
    func create(placeID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {}
    func fetchSummary(placeID: Int, level: ReviewLevelFilter) async throws(NetworkError) -> PlaceReviewSummary { fatalError() }
    func fetchReviews(placeID: Int, query: PlaceReviewQuery) async throws(NetworkError) -> PlaceReviewPage { fatalError() }
    func fetchMyReviews(query: MyReviewQuery) async throws(NetworkError) -> MyReviewPage { fatalError() }
    func delete(reviewID: Int) async throws(NetworkError) {}
    func fetchReportForm() async throws(NetworkError) -> ReviewReportForm { fatalError() }
    func report(reviewID: Int, submission: ReviewReportSubmission) async throws(NetworkError) {}
}

private struct MemberRepositoryStub: MemberRepository {
    func fetchMyProfile() async throws(NetworkError) -> MemberProfile { fatalError() }
    func withdraw() async throws(NetworkError) {}
    func block(memberID: Int) async throws(NetworkError) {}
    func fetchBlockedMembers(query: BlockedMemberQuery) async throws(NetworkError) -> BlockedMemberPage { fatalError() }
    func unblock(memberID: Int) async throws(NetworkError) {}
    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError) {}
    func updatePlaceFilterTags(_ tags: [PlacePracticeType]) async throws(NetworkError) {}
    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError) {}
}
