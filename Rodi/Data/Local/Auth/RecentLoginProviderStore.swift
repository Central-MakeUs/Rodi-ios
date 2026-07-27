//
//  RecentLoginProviderStore.swift
//  Rodi
//

import Foundation

/// 이 기기에서 서버 인증까지 마지막으로 성공한 소셜 로그인 제공자를 보관한다.
/// 토큰, OAuth credential, 사용자 식별자는 저장하지 않는다.
struct RecentLoginProviderStore {
    private enum Key {
        static let providerRawValue = "rodi.auth.recent-login-provider"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> SocialLoginProvider? {
        guard let rawValue = userDefaults.string(forKey: Key.providerRawValue) else {
            return nil
        }
        return SocialLoginProvider(rawValue: rawValue)
    }

    func save(_ provider: SocialLoginProvider) {
        userDefaults.set(provider.rawValue, forKey: Key.providerRawValue)
    }

    func clear() {
        userDefaults.removeObject(forKey: Key.providerRawValue)
    }
}
