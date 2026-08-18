import Foundation

final class ReviewRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func create(placeID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        let response = try await networkManager.request(
            ReviewAPI.create(placeID: placeID, request: .init(submission)),
            as: ServerResponse<ReviewCreateResponseDTO>.self
        )
        guard response.isSuccess, response.data != nil else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    func fetchDetail(reviewID: Int) async throws(NetworkError) -> ReviewDetailResponseDTO {
        try await request(.detail(reviewID: reviewID), as: ReviewDetailResponseDTO.self)
    }

    func update(reviewID: Int, submission: PlaceReviewSubmission) async throws(NetworkError) {
        try await empty(.update(reviewID: reviewID, request: .init(submission)))
    }

    func fetchSummary(
        placeID: Int,
        level: ReviewLevelFilter
    ) async throws(NetworkError) -> ReviewSummaryResponseDTO {
        try await request(
            .summary(placeID: placeID, level: level),
            as: ReviewSummaryResponseDTO.self
        )
    }

    func fetchReviews(
        placeID: Int,
        query: PlaceReviewQuery
    ) async throws(NetworkError) -> ReviewCursorPageResponseDTO {
        try await request(
            .list(placeID: placeID, query: query),
            as: ReviewCursorPageResponseDTO.self
        )
    }

    func fetchMyReviews(
        query: MyReviewQuery
    ) async throws(NetworkError) -> MyReviewCursorPageResponseDTO {
        try await request(
            .myReviews(query: query),
            as: MyReviewCursorPageResponseDTO.self
        )
    }

    func delete(reviewID: Int) async throws(NetworkError) {
        try await empty(.delete(reviewID: reviewID))
    }

    func fetchReportForm() async throws(NetworkError) -> ReviewReportFormResponseDTO {
        try await request(.reportForm, as: ReviewReportFormResponseDTO.self)
    }

    func report(
        reviewID: Int,
        submission: ReviewReportSubmission
    ) async throws(NetworkError) {
        try await empty(
            .report(reviewID: reviewID, request: .init(submission))
        )
    }

    private func empty(_ api: ReviewAPI) async throws(NetworkError) {
        let response = try await networkManager.request(api, as: ServerResponse<EmptyResponse>.self)
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    private func request<T: Decodable>(
        _ api: ReviewAPI,
        as type: T.Type
    ) async throws(NetworkError) -> T {
        let response = try await networkManager.request(api, as: ServerResponse<T>.self)
        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data
    }
}
