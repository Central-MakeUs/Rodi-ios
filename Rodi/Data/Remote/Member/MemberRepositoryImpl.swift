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

    func withdraw() async throws(NetworkError) {
        let response = try await networkManager.request(
            MemberTarget.withdraw,
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
