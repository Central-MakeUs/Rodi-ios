import Foundation

protocol ReviewWritingServicing {
    var usesServerForm: Bool { get }
    func fetchWritingForm(placeID: Int) async throws -> ReviewWritingForm
    func fetchReviewDetail(reviewID: Int) async throws -> ReviewDetail
    func createReview(placeID: Int, submission: PlaceReviewSubmission) async throws
    func updateReview(reviewID: Int, submission: PlaceReviewSubmission) async throws
}

struct ReviewWritingService: ReviewWritingServicing {
    private let reviewRepository: ReviewRepository
    let usesServerForm: Bool

    init(reviewRepository: ReviewRepository, usesServerForm: Bool) {
        self.reviewRepository = reviewRepository
        self.usesServerForm = usesServerForm
    }

    func fetchWritingForm(placeID: Int) async throws -> ReviewWritingForm {
        try await reviewRepository.fetchWritingForm(placeID: placeID)
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
