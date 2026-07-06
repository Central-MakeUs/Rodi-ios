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
