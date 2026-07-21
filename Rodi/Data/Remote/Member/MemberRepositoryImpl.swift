//
//  MemberRepositoryImpl.swift
//  Rodi
//

import Foundation

final class MemberRepositoryImpl: MemberRepository {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchMyProfile() async throws(NetworkError) -> MemberProfile {
        let response = try await networkManager.request(
            MemberTarget.myProfile,
            as: ServerResponse<MemberProfileResponseDTO>.self
        )

        #if DEBUG
        let profileLog: String
        if let profile = response.data {
            let drivingGoal = profile.drivingGoal ?? "nil"
            profileLog = "nickname=\(profile.nickname), level=\(profile.level), recommendationTags=\(profile.recommendationTags), drivingGoal=\(drivingGoal), savedPlaceCount=\(profile.savedPlaceCount)"
        } else {
            profileLog = "nil"
        }
        let traceID = response.traceId ?? "nil"
        RodiLogger.debug(
            "GET /api/v1/members/me response: isSuccess=\(response.isSuccess), code=\(response.code), message=\(response.message), traceId=\(traceID), data={\(profileLog)}"
        )
        #endif

        guard response.isSuccess, let profile = response.data else {
            throw .apiError(code: response.code, message: response.message)
        }

        return try profile.toDomain()
    }

    func withdraw() async throws(NetworkError) {
        let response = try await networkManager.request(
            MemberTarget.withdraw,
            as: ServerResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError) {
        let response = try await networkManager.request(
            MemberTarget.updateDrivingGoal(MemberDrivingGoalUpdateRequestDTO(drivingGoal: drivingGoal)),
            as: ServerResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }

    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError) {
        let response = try await networkManager.request(
            MemberTarget.submitOnboarding(MemberOnboardingRequestDTO(submission)),
            as: ServerResponse<EmptyResponse>.self
        )

        guard response.isSuccess else {
            throw .apiError(code: response.code, message: response.message)
        }
    }
}
