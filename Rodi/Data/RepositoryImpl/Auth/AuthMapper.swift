import Foundation

extension SocialLoginResponseDTO {
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
        }
    }
    private func date(
        _ value: String?
    ) -> Date? {
        guard let value else {
            return nil
        }; return ISO8601DateFormatter().date(
            from: value
        )
    }
}
