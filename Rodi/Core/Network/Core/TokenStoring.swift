//
//  TokenStoring.swift
//  Rodi
//
//  Created by Codex on 7/4/26.
//

import Foundation

struct TokenRefreshResult {
    let accessToken: String
    let refreshToken: String
}

protocol TokenStoring: AnyObject {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }

    func update(accessToken: String, refreshToken: String)
    func clear()
}

final class InMemoryTokenStore: TokenStoring {
    var accessToken: String?
    var refreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func update(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}
