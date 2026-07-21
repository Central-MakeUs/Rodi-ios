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
    func loginResult(provider: AuthProvider) throws(NetworkError) -> AuthLoginResult {
        switch status {
        case .success:
            guard let accessToken, !accessToken.isEmpty,
                  let refreshToken, !refreshToken.isEmpty
            else {
                throw .apiError(code: "AUTH_INVALID_TOKEN_RESPONSE", message: "로그인 토큰을 확인하지 못했어요.")
            }
            return .authenticated(
                AuthToken(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    isNewMember: isNewMember ?? false,
                    nickname: nickname?.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )

        case .withdrawalPending:
            return .withdrawalPending(
                AuthWithdrawalRecovery(
                    provider: provider,
                    withdrawalRequestedAt: Self.date(from: withdrawalRequestedAt),
                    recoverableUntil: Self.date(from: recoverableUntil)
                )
            )
        }
    }

    private static func date(from value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

extension AuthTokenDTO {
    var domain: AuthToken {
        AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            isNewMember: isNewMember,
            nickname: nil
        )
    }

    var refreshResult: TokenRefreshResult {
        TokenRefreshResult(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
