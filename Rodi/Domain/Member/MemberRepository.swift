//
//  MemberRepository.swift
//  Rodi
//

import Foundation

protocol MemberRepository {
    /// 마이페이지에 표시할 회원 요약 정보를 조회한다.
    func fetchMyProfile() async throws(NetworkError) -> MemberProfile

    /// 현재 로그인한 회원을 탈퇴 처리한다.
    func withdraw() async throws(NetworkError)

    /// 마이페이지에서 운전 목표를 부분 수정한다.
    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError)

    /// 온보딩에서 수집한 운전 경험과 선호 정보를 제출한다.
    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError)
}
