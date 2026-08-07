import Foundation

final class MemberRemoteDataSource {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchProfile() async throws(NetworkError) -> MemberProfileResponseDTO {
        let response = try await networkManager.request(
            MemberAPI.myProfile,
            as: ServerResponse<MemberProfileResponseDTO>.self
        )
        logProfileResponse(response)

        guard response.isSuccess, let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        return data
    }
    
    func withdraw() async throws(NetworkError) { try await empty(.withdraw) }
    
    func updateDrivingGoal(_ request: MemberDrivingGoalUpdateRequestDTO) async throws(NetworkError) {
        try await empty(.updateDrivingGoal(request))
    }
    
    func updateFilterTags(_ request: MemberPlaceFilterTagsUpdateRequestDTO) async throws(NetworkError) {
        try await empty(.updatePlaceFilterTags(request))
    }
    
    func submitOnboarding(_ request: MemberOnboardingRequestDTO) async throws(NetworkError) {
        try await empty(.submitOnboarding(request))
    }

    private func response<T: Decodable>(_ api: MemberAPI, as type: T.Type) async throws(NetworkError) -> T {
        let response = try await networkManager.request(api, as: ServerResponse<T>.self)
        guard response.isSuccess,
              let data = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }
        
        return data
    }
    
    private func empty(_ api: MemberAPI) async throws(NetworkError) {
        let response = try await networkManager.request(api, as: ServerResponse<EmptyResponse>.self)
        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    private func logProfileResponse(_ response: ServerResponse<MemberProfileResponseDTO>) {
        #if DEBUG
        let dataDescription: String
        if let data = response.data {
            dataDescription = """
            nickname=\(data.nickname), \
            level=\(data.level), \
            recommendationTags=\(data.recommendationTags), \
            drivingGoal=\(data.drivingGoal ?? "nil"), \
            savedPlaceCount=\(data.savedPlaceCount)
            """
        } else {
            dataDescription = "nil"
        }

        RodiLogger.debug(
            "회원 프로필 응답: code=\(response.code), message=\(response.message), isSuccess=\(response.isSuccess), traceId=\(response.traceId ?? "nil"), data={\(dataDescription)}"
        )
        #endif
    }
}
