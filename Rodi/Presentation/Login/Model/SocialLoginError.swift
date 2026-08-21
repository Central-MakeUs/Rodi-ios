//
//  SocialLoginError.swift
//  Rodi
//

import Foundation

enum SocialLoginError: LocalizedError {
    case appleAuthorizationCancelled
    case invalidAppleCredential
    case invalidAppleAuthorizationCode
    case kakaoSDKUnavailable
    case emptyKakaoToken
    case kakaoLoginCancelled
    case kakaoLoginTimedOut
    case kakaoLoginAlreadyInProgress
    case appleLoginAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .appleAuthorizationCancelled:
            "Apple 로그인을 취소했어요."
        case .invalidAppleCredential:
            "Apple 로그인 정보를 확인하지 못했어요."
        case .invalidAppleAuthorizationCode:
            "Apple 인증 코드를 확인하지 못했어요."
        case .kakaoSDKUnavailable:
            "카카오 로그인 SDK가 연결되어 있지 않아요."
        case .emptyKakaoToken:
            "카카오 로그인 토큰을 확인하지 못했어요."
        case .kakaoLoginCancelled:
            "카카오 로그인을 취소했어요."
        case .kakaoLoginTimedOut:
            "카카오 로그인 시간이 초과되었어요. 다시 시도해 주세요."
        case .kakaoLoginAlreadyInProgress:
            "카카오 로그인이 이미 진행 중이에요."
        case .appleLoginAlreadyInProgress:
            "Apple 로그인이 이미 진행 중이에요."
        }
    }
}
