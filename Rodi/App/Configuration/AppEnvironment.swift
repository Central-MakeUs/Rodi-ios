//
//  AppEnvironment.swift
//  Rodi
//

import Foundation

enum AppEnvironment: String {
    case development = "dev"
    case production = "prod"

    static var current: Self {
        let configuredValue = Bundle.main.rodiConfigurationString(for: "RODI_ENVIRONMENT")

        guard let environment = Self(rawValue: configuredValue) else {
            assertionFailure("RODI_ENVIRONMENT must be configured as dev or prod.")
            return .development
        }

        return environment
    }

    var isProduction: Bool {
        self == .production
    }
}

extension Bundle {
    func rodiConfigurationString(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return "" }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
