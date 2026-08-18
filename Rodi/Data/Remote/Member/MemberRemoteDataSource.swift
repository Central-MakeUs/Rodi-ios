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

    func hardWithdraw() async throws(NetworkError) { try await empty(.hardWithdraw) }

    func block(memberID: Int) async throws(NetworkError) {
        try await empty(.block(memberID: memberID))
    }

    func fetchBlockedMembers(
        query: BlockedMemberQuery
    ) async throws(NetworkError) -> BlockedMemberCursorPageResponseDTO {
        try await response(.blockedMembers(query: query), as: BlockedMemberCursorPageResponseDTO.self)
    }

    func unblock(memberID: Int) async throws(NetworkError) {
        try await empty(.unblock(memberID: memberID))
    }
    
    func updateDrivingGoal(_ request: MemberDrivingGoalUpdateRequestDTO) async throws(NetworkError) {
        try await empty(.updateDrivingGoal(request))
    }
    
    func updateFilterTags(_ request: MemberPlaceFilterTagsUpdateRequestDTO) async throws(NetworkError) {
        try await empty(.updatePlaceFilterTags(request))
    }
    
    func submitOnboarding(_ request: MemberOnboardingRequestDTO) async throws(NetworkError) {
        try await empty(.submitOnboarding(request))
    }

    func completeCourseTutorial() async throws(NetworkError) -> CourseTutorialCompletionResponseDTO {
        try await response(.completeCourseTutorial, as: CourseTutorialCompletionResponseDTO.self)
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
            let levelProgressDescription: String
            if let levelProgress = data.levelProgress {
                let nextLevelKm = levelProgress.nextLevelKm.map { String($0) } ?? "nil"
                levelProgressDescription = "levelProgress={totalDistanceKm=\(levelProgress.totalDistanceKm), currentLevelStartKm=\(levelProgress.currentLevelStartKm), nextLevelKm=\(nextLevelKm), progressPercent=\(levelProgress.progressPercent)}"
            } else {
                levelProgressDescription = "levelProgress=nil"
            }

            dataDescription = """
            nickname=\(data.nickname), \
            level=\(data.level), \
            recommendationTags=\(data.recommendationTags), \
            drivingGoal=\(data.drivingGoal ?? "nil"), \
            savedPlaceCount=\(data.savedPlaceCount), \
            \(levelProgressDescription)
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
