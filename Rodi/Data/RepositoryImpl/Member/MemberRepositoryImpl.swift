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
        try MemberMapper.profile(from: await remoteDataSource.fetchProfile())
    }

    func withdraw() async throws(NetworkError) {
        try await remoteDataSource.withdraw()
    }

    func hardWithdraw() async throws(NetworkError) {
        try await remoteDataSource.hardWithdraw()
    }

    func block(memberID: Int) async throws(NetworkError) {
        try await remoteDataSource.block(memberID: memberID)
    }

    func fetchBlockedMembers(query: BlockedMemberQuery) async throws(NetworkError) -> BlockedMemberPage {
        try MemberMapper.blockedMemberPage(
            from: await remoteDataSource.fetchBlockedMembers(
                query: .init(query)
            )
        )
    }

    func unblock(memberID: Int) async throws(NetworkError) {
        try await remoteDataSource.unblock(memberID: memberID)
    }

    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError) {
        try await remoteDataSource.updateDrivingGoal(
            MemberMapper.drivingGoalRequest(from: drivingGoal)
        )
    }

    func updatePlaceFilterTags(_ tags: [PlacePracticeType]) async throws(NetworkError) {
        try await remoteDataSource.updateFilterTags(
            MemberMapper.placeFilterTagsRequest(from: tags)
        )
    }

    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError) {
        try await remoteDataSource.submitOnboarding(
            MemberMapper.onboardingRequest(from: submission)
        )
    }

    func completeCourseTutorial() async throws(NetworkError) -> CourseTutorialCompletion {
        let response = try await remoteDataSource.completeCourseTutorial()
        return .init(completedAt: response.courseTutorialCompletedAt)
    }
}
