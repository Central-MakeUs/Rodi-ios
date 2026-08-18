import Alamofire
import Foundation

final class PracticeRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func register(placeID: Int) async throws(NetworkError) -> PracticeRegisterResponseDTO {
        try await request(.register(placeID: placeID), as: PracticeRegisterResponseDTO.self)
    }

    func recordVisit(
        practiceID: Int,
        certifiedDistanceMeters: Int?
    ) async throws(NetworkError) -> PracticeVisitResponseDTO {
        try await request(
            .recordVisit(
                practiceID: practiceID,
                request: .init(certifiedDistanceMeters: certifiedDistanceMeters)
            ),
            as: PracticeVisitResponseDTO.self
        )
    }

    func fetchMyPractices(
        query: MyPracticeQuery
    ) async throws(NetworkError) -> MyPracticeCursorPageResponseDTO {
        try await request(.myPractices(query: query), as: MyPracticeCursorPageResponseDTO.self)
    }

    func fetchSkipReasonForm() async throws(NetworkError) -> PracticeSkipReasonFormResponseDTO {
        try await request(.skipReasonForm, as: PracticeSkipReasonFormResponseDTO.self)
    }

    func submitSkipReason(
        practiceID: Int,
        reasonCode: String,
        detail: String?
    ) async throws(NetworkError) {
        try await empty(
            .submitSkipReason(
                practiceID: practiceID,
                request: .init(reasonCode: reasonCode, detail: detail)
            )
        )
    }

    private func empty(_ api: PracticeAPI) async throws(NetworkError) {
        let response = try await networkManager.request(api, as: ServerResponse<EmptyResponse>.self)

        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    private func request<T: Decodable>(_ api: PracticeAPI, as type: T.Type) async throws(NetworkError) -> T {
        let response = try await networkManager.request(api, as: ServerResponse<T>.self)

        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }

        guard let data = response.data else {
            throw .decodingFail
        }

        return data
    }
}
