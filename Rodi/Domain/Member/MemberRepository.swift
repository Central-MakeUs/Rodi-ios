//
//  MemberRepository.swift
//  Rodi
//

import Foundation

protocol MemberRepository {
    /// 현재 로그인한 회원을 탈퇴 처리한다.
    func withdraw() async throws(NetworkError)
}
