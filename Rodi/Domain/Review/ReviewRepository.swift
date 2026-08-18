import Foundation

protocol ReviewRepository {
    func create(placeID: Int, submission: PlaceReviewSubmission) async throws(NetworkError)
    func fetchDetail(reviewID: Int) async throws(NetworkError) -> ReviewDetail
    func update(reviewID: Int, submission: PlaceReviewSubmission) async throws(NetworkError)
    func fetchSummary(placeID: Int, level: ReviewLevelFilter) async throws(NetworkError) -> PlaceReviewSummary
    func fetchReviews(placeID: Int, query: PlaceReviewQuery) async throws(NetworkError) -> PlaceReviewPage
    func fetchMyReviews(query: MyReviewQuery) async throws(NetworkError) -> MyReviewPage
    func delete(reviewID: Int) async throws(NetworkError)
    func fetchReportForm() async throws(NetworkError) -> ReviewReportForm
    func report(reviewID: Int, submission: ReviewReportSubmission) async throws(NetworkError)
}
