//
//  KeychainTokenStore.swift
//  Rodi
//

import Foundation
import Security

final class KeychainTokenStore: TokenStoring {
    private enum Account {
        static let session = "authSession"
        static let legacyAccessToken = "accessToken"
        static let legacyRefreshToken = "refreshToken"
    }

    private struct Session: Codable {
        var accessToken: String?
        var refreshToken: String?
    }

    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.dororong.rodi") {
        self.service = "\(service).auth"
    }

    var accessToken: String? {
        get { session()?.accessToken }
        set {
            var session = session() ?? .init(accessToken: nil, refreshToken: nil)
            session.accessToken = newValue
            write(session)
        }
    }

    var refreshToken: String? {
        get { session()?.refreshToken }
        set {
            var session = session() ?? .init(accessToken: nil, refreshToken: nil)
            session.refreshToken = newValue
            write(session)
        }
    }

    func update(accessToken: String, refreshToken: String) {
        write(.init(accessToken: accessToken, refreshToken: refreshToken))
    }

    func clear() {
        delete(account: Account.session)
        delete(account: Account.legacyAccessToken)
        delete(account: Account.legacyRefreshToken)
    }
}

private extension KeychainTokenStore {
    private func session() -> Session? {
        if let session = readSession(account: Account.session) {
            return session
        }

        let legacySession = Session(
            accessToken: readString(account: Account.legacyAccessToken),
            refreshToken: readString(account: Account.legacyRefreshToken)
        )
        guard legacySession.accessToken != nil || legacySession.refreshToken != nil else { return nil }

        write(legacySession)
        delete(account: Account.legacyAccessToken)
        delete(account: Account.legacyRefreshToken)
        return legacySession
    }

    private func write(_ session: Session) {
        guard session.accessToken?.isEmpty == false || session.refreshToken?.isEmpty == false else {
            delete(account: Account.session)
            return
        }

        guard let data = try? JSONEncoder().encode(session) else {
            RodiLogger.warning("Keychain token session encoding failed")
            return
        }

        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(baseQuery(account: Account.session) as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var query = baseQuery(account: Account.session)
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            if addStatus != errSecSuccess {
                RodiLogger.warning("Keychain token session add failed status=\(addStatus)")
            }
        default:
            RodiLogger.warning("Keychain token session update failed status=\(status)")
        }
    }

    private func readSession(account: String) -> Session? {
        guard let data = readData(account: account) else { return nil }
        return try? JSONDecoder().decode(Session.self, from: data)
    }

    func readString(account: String) -> String? {
        guard let data = readData(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func readData(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
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
