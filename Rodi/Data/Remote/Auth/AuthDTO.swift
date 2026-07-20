//
//  AuthDTO.swift
//  Rodi
//

import Foundation

struct SocialLoginRequestDTO: Encodable {
    let credential: String
}

struct TokenRefreshRequestDTO: Encodable {
    let refreshToken: String
}

struct LogoutRequestDTO: Encodable {
    let refreshToken: String
}

struct AuthTokenDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let isNewMember: Bool
}

/// 소셜 로그인만 사용하는 서버 응답입니다.
/// 탈퇴 유예 상태에서는 HTTP 200이어도 토큰이 null로 내려올 수 있습니다.
struct SocialLoginResponseDTO: Decodable {
    enum Status: String, Decodable {
        case success = "SUCCESS"
        case withdrawalPending = "WITHDRAWAL_PENDING"
    }

    let status: Status
    let accessToken: String?
    let refreshToken: String?
    let isNewMember: Bool?
    let nickname: String?
    let withdrawalRequestedAt: String?
    let recoverableUntil: String?
}

extension SocialLoginResponseDTO {
    func validatedToken() throws(NetworkError) -> AuthToken {
        switch status {
        case .success:
            guard let accessToken, !accessToken.isEmpty,
                  let refreshToken, !refreshToken.isEmpty
            else {
                throw .apiError(code: "AUTH_INVALID_TOKEN_RESPONSE", message: "로그인 토큰을 확인하지 못했어요.")
            }
            return AuthToken(
                accessToken: accessToken,
                refreshToken: refreshToken,
                isNewMember: isNewMember ?? false
            )

        case .withdrawalPending:
            throw .apiError(
                code: "AUTH_WITHDRAWAL_PENDING",
                message: "탈퇴 처리 중인 계정입니다. 복구가 필요하면 고객지원에 문의해주세요."
            )
        }
    }
}

extension AuthTokenDTO {
    var domain: AuthToken {
        AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            isNewMember: isNewMember
        )
    }

    var refreshResult: TokenRefreshResult {
        TokenRefreshResult(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
