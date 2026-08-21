import Foundation

final class ReviewRepositoryImpl: ReviewRepository {
    private let remoteDataSource: ReviewRemoteDataSource

    init(remoteDataSource: ReviewRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func create(placeID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        try await remoteDataSource.create(placeID: placeID, request: .init(submission))
    }

    func fetchDetail(reviewID: Int) async throws(NetworkError) -> ReviewDetail {
        try ReviewMapper.detail(
            from: await remoteDataSource.fetchDetail(reviewID: reviewID)
        )
    }

    func update(reviewID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        try await remoteDataSource.update(reviewID: reviewID, request: .init(submission))
    }

    func fetchSummary(
        placeID: Int,
        level: ReviewLevelFilter
    ) async throws(NetworkError) -> PlaceReviewSummary {
        try ReviewMapper.summary(
            from: await remoteDataSource.fetchSummary(
                placeID: placeID,
                query: .init(level)
            )
        )
    }

    func fetchReviews(
        placeID: Int,
        query: PlaceReviewQuery
    ) async throws(NetworkError) -> PlaceReviewPage {
        try ReviewMapper.placeReviewPage(
            from: await remoteDataSource.fetchReviews(
                placeID: placeID,
                query: .init(query)
            )
        )
    }

    func fetchMyReviews(query: MyReviewQuery) async throws(NetworkError) -> MyReviewPage {
        try ReviewMapper.myReviewPage(
            from: await remoteDataSource.fetchMyReviews(query: .init(query))
        )
    }

    func delete(reviewID: Int) async throws(NetworkError) {
        try await remoteDataSource.delete(reviewID: reviewID)
    }

    func fetchReportForm() async throws(NetworkError) -> ReviewReportForm {
        ReviewMapper.reportForm(
            from: try await remoteDataSource.fetchReportForm()
        )
    }

    func report(reviewID: Int, submission: ReviewReportSubmission) async throws(NetworkError) {
        try await remoteDataSource.report(reviewID: reviewID, request: .init(submission))
    }
}
