import Foundation

final class AuthRemoteDataSource {
    private let networkManager: NetworkManager

    init(
        networkManager: NetworkManager
    ) {
        self.networkManager = networkManager
    }
    
    func login(
        providerRawValue: String,
        request: SocialLoginRequestDTO
    ) async throws(
        NetworkError
    ) -> SocialLoginResponseDTO {
        logSocialLoginStarted(providerRawValue: providerRawValue)

        return try await ServerResponseHandler.payload(
            AuthAPI.login(
                providerRawValue: providerRawValue,
                request: request
            ),
            using: networkManager,
            as: SocialLoginResponseDTO.self
        )
    }
    
    func restore(
        providerRawValue: String,
        request: SocialLoginRequestDTO
    ) async throws(
        NetworkError
    ) -> SocialLoginResponseDTO {
        try await ServerResponseHandler.payload(
            AuthAPI.restore(
                providerRawValue: providerRawValue,
                request: request
            ),
            using: networkManager,
            as: SocialLoginResponseDTO.self
        )
    }
    
    func logout(
        _ request: LogoutRequestDTO
    ) async throws(
        NetworkError
    ) {
        try await ServerResponseHandler.empty(
            AuthAPI.logout(
                request: request
            ),
            using: networkManager
        )
    }

    func refresh(
        _ request: TokenRefreshRequestDTO
    ) async throws(NetworkError) -> TokenRefreshResponseDTO {
        try await ServerResponseHandler.payload(
            AuthAPI.refresh(request: request),
            using: networkManager,
            as: TokenRefreshResponseDTO.self
        )
    }

    private func logSocialLoginStarted(
        providerRawValue: String
    ) {
        #if DEBUG
        RodiLogger.debug(
            "소셜 로그인 요청 시작: provider=\(providerRawValue)"
        )
        #endif
    }
}
