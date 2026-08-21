//
//  LevelUpPresentationStore.swift
//  Rodi
//

import CryptoKit
import Foundation

struct LevelUpPresentationCheckResult {
    let previousLevel: MemberProfile.Level?
    let levelToPresent: MemberProfile.Level?
}

final class LevelUpPresentationStore {
    private enum Key {
        static let prefix = "rodi.level-up-presentation"
    }

    private struct Snapshot: Codable {
        var highestKnownLevel: String
        var presentedLevels: Set<String>
    }

    private let tokenStore: TokenStoring

    init(
        tokenStore: TokenStoring
    ) {
        self.tokenStore = tokenStore
    }

    func check(level: MemberProfile.Level) -> LevelUpPresentationCheckResult {
        guard let storageKey = storageKey else {
            return .init(previousLevel: nil, levelToPresent: nil)
        }

        guard var snapshot = snapshot(forKey: storageKey),
              let previousLevel = MemberProfile.Level(rawValue: snapshot.highestKnownLevel)
        else {
            save(
                .init(highestKnownLevel: level.rawValue, presentedLevels: []),
                forKey: storageKey
            )
            return .init(previousLevel: nil, levelToPresent: nil)
        }

        guard level.rank > previousLevel.rank else {
            return .init(previousLevel: previousLevel, levelToPresent: nil)
        }

        snapshot.highestKnownLevel = level.rawValue
        let shouldPresent = snapshot.presentedLevels.insert(level.rawValue).inserted
        save(snapshot, forKey: storageKey)

        return .init(
            previousLevel: previousLevel,
            levelToPresent: shouldPresent ? level : nil
        )
    }
}

// MARK: - Persistence
private extension LevelUpPresentationStore {
    private var storageKey: String? {
        guard let subject = accessTokenSubject else { return nil }
        let digest = SHA256.hash(data: Data(subject.utf8))
        let accountHash = digest.map { String(format: "%02x", $0) }.joined()
        return "\(Key.prefix).\(accountHash)"
    }

    private var accessTokenSubject: String? {
        guard let accessToken = tokenStore.accessToken,
              !accessToken.isEmpty
        else {
            return nil
        }

        let segments = accessToken.split(separator: ".")
        guard segments.count >= 2,
              let payloadData = base64URLDecodedData(from: String(segments[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let subject = payload["sub"] as? String,
              !subject.isEmpty
        else {
            return nil
        }

        return subject
    }

    private func snapshot(forKey key: String) -> Snapshot? {
        UserDefaultsCodableStore<Snapshot>(key: key).load()
    }

    private func save(_ snapshot: Snapshot, forKey key: String) {
        UserDefaultsCodableStore<Snapshot>(key: key).save(snapshot)
    }

    private func base64URLDecodedData(from value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64.append(String(repeating: "=", count: (4 - base64.count % 4) % 4))
        return Data(base64Encoded: base64)
    }
}

// MARK: - Level
private extension MemberProfile.Level {
    var rank: Int {
        switch self {
        case .seed: 0
        case .rookie: 1
        case .owner: 2
        case .explorer: 3
        case .navigator: 4
        }
    }
}
