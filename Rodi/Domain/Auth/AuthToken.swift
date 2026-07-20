//
//  AuthToken.swift
//  Rodi
//

import Foundation

struct AuthToken: Equatable {
    let accessToken: String
    let refreshToken: String
    let isNewMember: Bool
    let nickname: String?
}
