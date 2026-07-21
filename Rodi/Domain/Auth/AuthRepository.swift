//
//  AuthRepository.swift
//  Rodi
//

import Foundation

protocol AuthRepository {
    func login(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthLoginResult
    func restore(provider: AuthProvider, credential: String) async throws(NetworkError) -> AuthToken
    func refreshToken() async throws(NetworkError) -> AuthToken
    func logout() async throws(NetworkError)
    func clearSession()
}
