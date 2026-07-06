//
//  AuthInterceptor.swift
//  BoilerplateSwiftUI
//
//  Created by mac on 5/12/26.
//

import Foundation

@MainActor
protocol AccessTokenRefreshing: AnyObject {
    func refreshAccessToken() async throws(NetworkError) -> TokenRefreshResult?
}

final class AuthInterceptor {
    private var tokenStore: TokenStoring
    private let tokenRefresher: AccessTokenRefreshing?

    init(
        tokenStore: TokenStoring,
        tokenRefresher: AccessTokenRefreshing? = nil
    ) {
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
    }

    func adapt(_ request: URLRequest, for target: any TargetType) -> URLRequest {
        guard target.requiresAuthentication,
              let accessToken = tokenStore.accessToken,
              accessToken.isEmpty == false,
              request.value(forHTTPHeaderField: "Authorization") == nil else {
            return request
        }

        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        RodiLogger.debug("Attached authorization header")
        return request
    }

    func refreshAccessToken() async throws(NetworkError) -> TokenRefreshResult? {
        guard let refreshedToken = try await tokenRefresher?.refreshAccessToken(),
              !refreshedToken.accessToken.isEmpty,
              !refreshedToken.refreshToken.isEmpty else {
            return nil
        }

        tokenStore.update(
            accessToken: refreshedToken.accessToken,
            refreshToken: refreshedToken.refreshToken
        )
        RodiLogger.info("Access token refreshed")
        return refreshedToken
    }
}
