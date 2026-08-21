import Foundation

nonisolated enum AuthMapper {
    static func socialLoginRequest(
        credential: String
    ) -> SocialLoginRequestDTO {
        .init(credential: credential)
    }

    static func logoutRequest(
        refreshToken: String
    ) -> LogoutRequestDTO {
        .init(refreshToken: refreshToken)
    }

    static func tokenRefreshRequest(
        refreshToken: String
    ) -> TokenRefreshRequestDTO {
        .init(refreshToken: refreshToken)
    }
}

nonisolated extension SocialLoginResponseDTO {
    func loginResult(
        provider: SocialLoginProvider
    ) throws(
        NetworkError
    ) -> AuthLoginResult {
        switch status {
        case .success:
            guard let accessToken, let refreshToken, !accessToken.isEmpty, !refreshToken.isEmpty else {
                throw .apiError(
                    code: "AUTH_INVALID_TOKEN_RESPONSE",
                    message: "로그인 토큰을 확인하지 못했어요."
                )
            }
            return .authenticated(
                .init(
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    isNewMember: isNewMember ?? false,
                    isOnboarded: isOnboarded ?? false,
                    isCourseTutorialCompleted: isCourseTutorialCompleted ?? false,
                    nickname: nickname?.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                )
            )
        case .withdrawalPending:
            return .withdrawalPending(
                .init(
                    provider: provider,
                    withdrawalRequestedAt: date(
                        withdrawalRequestedAt
                    ),
                    recoverableUntil: date(
                        recoverableUntil
                    )
                )
            )
        case .withdrawalLocked:
            return .withdrawalLocked(
                rejoinAvailableAt: date(reRegisterableAt)
            )
        }
    }
    private func date(
        _ value: String?
    ) -> Date? {
        ServerDateParser.date(from: value)
    }
}
