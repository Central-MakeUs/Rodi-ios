//
//  AppAPIConfiguration.swift
//  Rodi
//

import Foundation

enum AppAPIConfiguration {
    static var baseURL: String {
        let configuredURL = Bundle.main.configurationString(for: "RODI_API_BASE_URL")
        return configuredURL.isEmpty ? "https://api.stillstar.store" : configuredURL
    }
}

private extension Bundle {
    func configurationString(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return "" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
