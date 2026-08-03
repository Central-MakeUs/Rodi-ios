import Foundation

final class MemberRemoteDataSource {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchProfile() async throws(NetworkError) -> MemberProfileResponseDTO {
        try await response(.myProfile, as: MemberProfileResponseDTO.self)
    }
    
    func withdraw() async throws(NetworkError) { try await empty(.withdraw) }
    
    func updateDrivingGoal(_ request: MemberDrivingGoalUpdateRequestDTO) async throws(NetworkError) {
        try await empty(.updateDrivingGoal(request))
    }
    
    func updateFilterTags(_ request: MemberPlaceFilterTagsUpdateRequestDTO) async throws(NetworkError) { try await empty(.updatePlaceFilterTags(request))
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
        _ = try await response(api, as: EmptyResponse.self)
    }
}
