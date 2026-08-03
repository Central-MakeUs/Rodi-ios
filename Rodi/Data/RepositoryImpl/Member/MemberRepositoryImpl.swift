//
//  MemberRepositoryImpl.swift
//  Rodi
//

import Foundation

// Member remote DTO를 앱의 회원 계약으로 변환한다.

final class MemberRepositoryImpl: MemberRepository {
    private let remoteDataSource: MemberRemoteDataSource

    init(remoteDataSource: MemberRemoteDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchMyProfile() async throws(NetworkError) -> MemberProfile {
        let profile = try await remoteDataSource.fetchProfile()

        #if DEBUG
        let profileLog: String
        let drivingGoal = profile.drivingGoal ?? "nil"
        profileLog = "nickname=\(profile.nickname), level=\(profile.level), recommendationTags=\(profile.recommendationTags), drivingGoal=\(drivingGoal), savedPlaceCount=\(profile.savedPlaceCount)"
        RodiLogger.debug(
            "GET /api/v1/members/me response: data={\(profileLog)}"
        )
        #endif

        return try profile.toDomain()
    }

    func withdraw() async throws(NetworkError) {
        try await remoteDataSource.withdraw()
    }

    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError) {
        try await remoteDataSource.updateDrivingGoal(.init(drivingGoal: drivingGoal))
    }

    func updatePlaceFilterTags(_ tags: [PlacePracticeType]) async throws(NetworkError) {
        try await remoteDataSource.updateFilterTags(.init(tags))
    }

    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError) {
        try await remoteDataSource.submitOnboarding(.init(submission))
    }
}
