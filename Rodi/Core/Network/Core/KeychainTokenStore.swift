//
//  KeychainTokenStore.swift
//  Rodi
//

import Foundation
import Security

final class KeychainTokenStore: TokenStoring {
    private enum Account {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.dororong.rodi") {
        self.service = "\(service).auth"
    }

    var accessToken: String? {
        get { read(account: Account.accessToken) }
        set { write(newValue, account: Account.accessToken) }
    }

    var refreshToken: String? {
        get { read(account: Account.refreshToken) }
        set { write(newValue, account: Account.refreshToken) }
    }

    func update(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clear() {
        delete(account: Account.accessToken)
        delete(account: Account.refreshToken)
    }
}

private extension KeychainTokenStore {
    func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    func write(_ value: String?, account: String) {
        delete(account: account)
        guard let value,
              value.isEmpty == false,
              let data = value.data(using: .utf8) else {
            return
        }

        var query = baseQuery(account: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            RodiLogger.warning("Keychain token write failed account=\(account) status=\(status)")
        }
    }

    func delete(account: String) {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            RodiLogger.warning("Keychain token delete failed account=\(account) status=\(status)")
        }
    }

    func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
