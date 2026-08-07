//
//  AppVersionUpdateChecker.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import Foundation

struct AppVersionUpdate: Identifiable, Equatable {
    let currentVersion: String
    let latestVersion: String
    let appStoreURL: URL

    var id: String {
        "\(currentVersion)-\(latestVersion)"
    }
}

enum AppVersionUpdateChecker {
    private struct LookupResponse: Decodable {
        let resultCount: Int
        let results: [LookupResult]
    }

    private struct LookupResult: Decodable {
        let version: String
        let trackId: Int?
        let trackViewUrl: URL?
    }

    static func checkForOptionalUpdate() async -> AppVersionUpdate? {
        guard
            let bundleIdentifier = Bundle.main.bundleIdentifier,
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let lookupURL = lookupURL(bundleIdentifier: bundleIdentifier)
        else {
            RodiLogger.warning("App version check skipped: bundle metadata unavailable")
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: lookupURL)
            let response = try JSONDecoder().decode(LookupResponse.self, from: data)

            guard response.resultCount > 0, let result = response.results.first else {
                RodiLogger.info("App version check skipped: App Store result not found")
                return nil
            }

            guard currentVersion.compare(result.version, options: .numeric) == .orderedAscending else {
                RodiLogger.info("App version is current: current=\(currentVersion), latest=\(result.version)")
                return nil
            }

            guard let appStoreURL = appStoreURL(from: result) else {
                RodiLogger.warning("App version update found but App Store URL is unavailable")
                return nil
            }

            RodiLogger.info("App version update available: current=\(currentVersion), latest=\(result.version)")
            return AppVersionUpdate(
                currentVersion: currentVersion,
                latestVersion: result.version,
                appStoreURL: appStoreURL
            )
        } catch {
            RodiLogger.warning("App version check failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func lookupURL(bundleIdentifier: String) -> URL? {
        let appID = configuredAppID

        if !appID.isEmpty {
            return URL(string: "https://itunes.apple.com/lookup?id=\(appID)&country=kr")
        }

        return URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)&country=kr")
    }

    private static func appStoreURL(from result: LookupResult) -> URL? {
        let appID = configuredAppID

        if !appID.isEmpty,
           let configuredURL = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") {
            return configuredURL
        }

        if let trackId = result.trackId,
           let directURL = URL(string: "itms-apps://itunes.apple.com/app/id\(trackId)") {
            return directURL
        }

        return result.trackViewUrl
    }

    private static var configuredAppID: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "APP_STORE_APP_ID") as? String else {
            return ""
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
