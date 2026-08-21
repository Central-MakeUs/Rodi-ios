import Foundation

protocol ReviewWritingServicing {
    func fetchReviewDetail(reviewID: Int) async throws -> ReviewDetail
    func createReview(placeID: Int, submission: PlaceReviewSubmission) async throws
    func updateReview(reviewID: Int, submission: PlaceReviewSubmission) async throws
}

struct ReviewWritingService: ReviewWritingServicing {
    private let reviewRepository: ReviewRepository

    init(reviewRepository: ReviewRepository) {
        self.reviewRepository = reviewRepository
    }

    func fetchReviewDetail(reviewID: Int) async throws -> ReviewDetail {
        try await reviewRepository.fetchDetail(reviewID: reviewID)
    }

    func createReview(placeID: Int, submission: PlaceReviewSubmission) async throws {
        try await reviewRepository.create(placeID: placeID, submission: submission)
    }

    func updateReview(reviewID: Int, submission: PlaceReviewSubmission) async throws {
        try await reviewRepository.update(reviewID: reviewID, submission: submission)
    }
}
