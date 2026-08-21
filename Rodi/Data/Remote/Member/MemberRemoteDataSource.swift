import Foundation

final class MemberRemoteDataSource {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchProfile() async throws(NetworkError) -> MemberProfileResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.myProfile,
            using: networkManager,
            as: MemberProfileResponseDTO.self
        )
    }
    
    func withdraw() async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.withdraw, using: networkManager)
    }

    func hardWithdraw() async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.hardWithdraw, using: networkManager)
    }

    func block(memberID: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.block(memberID: memberID), using: networkManager)
    }

    func fetchBlockedMembers(
        query: BlockedMemberListQueryDTO
    ) async throws(NetworkError) -> BlockedMemberCursorPageResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.blockedMembers(query: query),
            using: networkManager,
            as: BlockedMemberCursorPageResponseDTO.self
        )
    }

    func unblock(memberID: Int) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.unblock(memberID: memberID), using: networkManager)
    }
    
    func updateDrivingGoal(_ request: MemberDrivingGoalUpdateRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.updateDrivingGoal(request), using: networkManager)
    }
    
    func updateFilterTags(_ request: MemberPlaceFilterTagsUpdateRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.updatePlaceFilterTags(request), using: networkManager)
    }
    
    func submitOnboarding(_ request: MemberOnboardingRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.submitOnboarding(request), using: networkManager)
    }

    func completeCourseTutorial() async throws(NetworkError) -> CourseTutorialCompletionResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.completeCourseTutorial,
            using: networkManager,
            as: CourseTutorialCompletionResponseDTO.self
        )
    }

}
