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

    /// Debug 테스트에서만 사용하는 즉시 물리 탈퇴 요청이다.
    func hardWithdraw() async throws(NetworkError)

    /// 특정 회원을 차단한다.
    func block(memberID: Int) async throws(NetworkError)

    /// 현재 로그인한 회원이 차단한 회원 목록을 조회한다.
    func fetchBlockedMembers(query: BlockedMemberQuery) async throws(NetworkError) -> BlockedMemberPage

    /// 특정 회원의 차단을 해제한다.
    func unblock(memberID: Int) async throws(NetworkError)

    /// 마이페이지에서 운전 목표를 부분 수정한다.
    func updateDrivingGoal(_ drivingGoal: String) async throws(NetworkError)

    /// 홈 추천 목록의 연습유형 정렬 필터를 전체 교체한다.
    func updatePlaceFilterTags(_ tags: [PlacePracticeType]) async throws(NetworkError)

    /// 온보딩에서 수집한 운전 경험과 선호 정보를 제출한다.
    func submitOnboarding(_ submission: MemberOnboardingSubmission) async throws(NetworkError)

    /// 코스 등록 방법 튜토리얼 완료 상태를 서버에 저장한다.
    func completeCourseTutorial() async throws(NetworkError) -> CourseTutorialCompletion
}
