//
//  MemberRepository.swift
//  Rodi
//

import Foundation

protocol MemberRepository {
    /// 현재 로그인한 회원을 탈퇴 처리한다.
    func withdraw() async throws(NetworkError)

    /// 온보딩에서 수집한 운전 경험과 선호 정보를 제출한다.
    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError)
}
