//
//  AppAPIConfiguration.swift
//  Rodi
//

import Foundation

enum AppAPIConfiguration {
    static var baseURL: String {
        let configuredURL = Bundle.main.rodiConfigurationString(for: "RODI_API_BASE_URL")

        guard !configuredURL.isEmpty else {
            assertionFailure("RODI_API_BASE_URL must be configured for the active environment.")
            return ""
        }

        return configuredURL
    }
}
