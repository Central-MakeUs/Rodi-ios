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
        let response = try await networkManager.request(
            AuthAPI.login(
                provider: provider,
                request: request
            ),
            as: ServerResponse<SocialLoginResponseDTO>.self
        )

        if provider == .kakao {
            logKakaoLoginResponse(response)
        }

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

    private func logKakaoLoginResponse(
        _ response: ServerResponse<SocialLoginResponseDTO>
    ) {
        #if DEBUG
        let dataDescription: String
        if let data = response.data {
            dataDescription = """
            status=\(data.status.rawValue), \
            accessToken=\(data.accessToken ?? "nil"), \
            isNewMember=\(data.isNewMember?.description ?? "nil"), \
            nickname=\(data.nickname ?? "nil"), \
            withdrawalRequestedAt=\(data.withdrawalRequestedAt ?? "nil"), \
            recoverableUntil=\(data.recoverableUntil ?? "nil")
            """
        } else {
            dataDescription = "nil"
        }

        RodiLogger.debug(
            "윤수 카카오 OAuth 응답: code=\(response.code), message=\(response.message), isSuccess=\(response.isSuccess), data={\(dataDescription)}"
        )
        #endif
    }
}
