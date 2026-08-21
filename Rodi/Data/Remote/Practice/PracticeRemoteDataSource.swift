import Foundation

final class PracticeRemoteDataSource {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func register(placeID: Int) async throws(NetworkError) -> PracticeRegisterResponseDTO {
        try await ServerResponseHandler.payload(
            PracticeAPI.register(placeID: placeID),
            using: networkManager,
            as: PracticeRegisterResponseDTO.self,
            missingPayloadPolicy: .decodingFail
        )
    }

    func recordVisit(
        practiceID: Int,
        request visitRequest: PracticeVisitRequestDTO
    ) async throws(NetworkError) -> PracticeVisitResponseDTO {
        try await ServerResponseHandler.payload(
            PracticeAPI.recordVisit(
                practiceID: practiceID,
                request: visitRequest
            ),
            using: networkManager,
            as: PracticeVisitResponseDTO.self,
            missingPayloadPolicy: .decodingFail
        )
    }

    func fetchMyPractices(
        query: MyPracticeListQueryDTO
    ) async throws(NetworkError) -> MyPracticeCursorPageResponseDTO {
        try await ServerResponseHandler.payload(
            PracticeAPI.myPractices(query: query),
            using: networkManager,
            as: MyPracticeCursorPageResponseDTO.self,
            missingPayloadPolicy: .decodingFail
        )
    }

    func fetchSkipReasonForm() async throws(NetworkError) -> PracticeSkipReasonFormResponseDTO {
        try await ServerResponseHandler.payload(
            PracticeAPI.skipReasonForm,
            using: networkManager,
            as: PracticeSkipReasonFormResponseDTO.self,
            missingPayloadPolicy: .decodingFail
        )
    }

    func submitSkipReason(
        practiceID: Int,
        request skipReasonRequest: PracticeSkipReasonRequestDTO
    ) async throws(NetworkError) {
        try await ServerResponseHandler.empty(
            PracticeAPI.submitSkipReason(
                practiceID: practiceID,
                request: skipReasonRequest
            ),
            using: networkManager
        )
    }
}
