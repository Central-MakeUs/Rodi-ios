import Foundation

final class ReviewRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func create(placeID: Int, request: ReviewRequestDTO) async throws(NetworkError) {
        _ = try await ServerResponseHandler.payload(
            ReviewAPI.create(placeID: placeID, request: request),
            using: networkManager,
            as: ReviewCreateResponseDTO.self
        )
    }

    func fetchDetail(reviewID: Int) async throws(NetworkError) -> ReviewDetailResponseDTO {
        try await ServerResponseHandler.payload(
            ReviewAPI.detail(reviewID: reviewID),
            using: networkManager,
            as: ReviewDetailResponseDTO.self
        )
    }

    func update(reviewID: Int, request: ReviewRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(
            ReviewAPI.update(reviewID: reviewID, request: request),
            using: networkManager
        )
    }

    func fetchSummary(
        placeID: Int,
        query: ReviewSummaryQueryDTO
    ) async throws(NetworkError) -> ReviewSummaryResponseDTO {
        try await ServerResponseHandler.payload(
            ReviewAPI.summary(placeID: placeID, query: query),
            using: networkManager,
            as: ReviewSummaryResponseDTO.self
        )
    }

    func fetchReviews(
        placeID: Int,
        query: PlaceReviewListQueryDTO
    ) async throws(NetworkError) -> ReviewCursorPageResponseDTO {
        try await ServerResponseHandler.payload(
            ReviewAPI.list(placeID: placeID, query: query),
            using: networkManager,
            as: ReviewCursorPageResponseDTO.self
        )
    }

    func fetchMyReviews(
        query: MyReviewListQueryDTO
    ) async throws(NetworkError) -> MyReviewCursorPageResponseDTO {
        try await ServerResponseHandler.payload(
            ReviewAPI.myReviews(query: query),
            using: networkManager,
            as: MyReviewCursorPageResponseDTO.self
        )
    }

    func delete(reviewID: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(ReviewAPI.delete(reviewID: reviewID), using: networkManager)
    }

    func fetchReportForm() async throws(NetworkError) -> ReviewReportFormResponseDTO {
        try await ServerResponseHandler.payload(
            ReviewAPI.reportForm,
            using: networkManager,
            as: ReviewReportFormResponseDTO.self
        )
    }

    func report(
        reviewID: Int,
        request: ReviewReportRequestDTO
    ) async throws(NetworkError) {
        try await ServerResponseHandler.empty(
            ReviewAPI.report(reviewID: reviewID, request: request),
            using: networkManager
        )
    }
}
