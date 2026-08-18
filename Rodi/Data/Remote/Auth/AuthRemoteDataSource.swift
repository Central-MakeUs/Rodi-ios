import Foundation

final class AuthRemoteDataSource {
    private let networkManager: NetworkManager

    init(
        networkManager: NetworkManager
    ) {
        self.networkManager = networkManager
    }
    
    func login(
        provider: SocialLoginProvider,
        request: SocialLoginRequestDTO
    ) async throws(
        NetworkError
    ) -> SocialLoginResponseDTO {
        logSocialLoginRequest(request: request)

        let response = try await networkManager.request(
            AuthAPI.login(
                provider: provider,
                request: request
            ),
            as: ServerResponse<SocialLoginResponseDTO>.self
        )

        logSocialLoginResponse(response: response)

        guard response.isSuccess, let data = response.data else {
            throw .apiError(
                code: response.code,
                message: response.message
            )
        }
        return data
    }
    
    func restore(
        provider: SocialLoginProvider,
        request: SocialLoginRequestDTO
    ) async throws(
        NetworkError
    ) -> SocialLoginResponseDTO {
        try await response(
            AuthAPI.restore(
                provider: provider,
                request: request
            ),
            as: SocialLoginResponseDTO.self
        )
    }
    
    func logout(
        _ request: LogoutRequestDTO
    ) async throws(
        NetworkError
    ) {
        _ = try await response(
            AuthAPI.logout(
                request: request
            ),
            as: EmptyResponse.self
        )
    }
    
    private func response<T: Decodable>(
        _ api: AuthAPI,
        as type: T.Type
    ) async throws(
        NetworkError
    ) -> T {
        let response = try await networkManager.request(
            api,
            as: ServerResponse<T>.self
        )
        guard response.isSuccess, let data = response.data else {
            throw .apiError(
                code: response.code,
                message: response.message
            )
        }
        return data
    }

    private func logSocialLoginRequest(
        request: SocialLoginRequestDTO
    ) {
        #if DEBUG
        RodiLogger.debug(
            "소셜 로그인 POST 요청 credential=\(RodiLogger.masked(request.credential))"
        )
        #endif
    }

    private func logSocialLoginResponse(
        response: ServerResponse<SocialLoginResponseDTO>
    ) {
        #if DEBUG
        RodiLogger.debug(
            "소셜 로그인 POST 응답 accessToken=\(response.data?.accessToken.map(RodiLogger.masked) ?? "nil")"
        )
        #endif
    }
}
