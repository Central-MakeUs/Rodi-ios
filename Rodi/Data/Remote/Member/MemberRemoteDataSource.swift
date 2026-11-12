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

    func fetchOnboardingForm() async throws(NetworkError) -> MemberOnboardingFormResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.onboardingForm,
            using: networkManager,
            as: MemberOnboardingFormResponseDTO.self
        )
    }

    func checkNicknameAvailability(
        _ query: MemberNicknameAvailabilityQueryDTO
    ) async throws(NetworkError) -> MemberNicknameAvailabilityResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.nicknameAvailability(query),
            using: networkManager,
            as: MemberNicknameAvailabilityResponseDTO.self
        )
    }

    func updateSortTags(_ request: MemberSortTagsUpdateRequestDTO) async throws(NetworkError) {
        try await ServerResponseHandler.empty(MemberAPI.updateSortTags(request), using: networkManager)
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

    func updateNickname(
        _ request: MemberNicknameUpdateRequestDTO
    ) async throws(NetworkError) -> MemberNicknameUpdateResponseDTO {
        try await ServerResponseHandler.payload(
            MemberAPI.updateNickname(request),
            using: networkManager,
            as: MemberNicknameUpdateResponseDTO.self
        )
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
