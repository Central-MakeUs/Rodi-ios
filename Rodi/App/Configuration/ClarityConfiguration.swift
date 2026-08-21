//
//  ClarityConfiguration.swift
//  Rodi
//

import Clarity
import Foundation

enum ClarityConfiguration {

    static func initializeIfEnabled() {
        guard isEnabled else {
            RodiLogger.info("Clarity is disabled for the current environment")
            return
        }

        guard !projectID.isEmpty else {
            RodiLogger.error("Clarity initialization skipped: project ID is empty")
            return
        }

        let config = ClarityConfig(
            projectId: projectID,
            logLevel: logLevel
        )
        let didInitialize = ClaritySDK.initialize(config: config)
        RodiLogger.info(
            "Clarity initialization requested success=\(didInitialize) environment=\(environment)"
        )

        guard didInitialize else { return }
        let didRegisterSessionCallback = ClaritySDK.setOnSessionStartedCallback { _ in
            RodiLogger.info("Clarity session started environment=\(environment)")
        }
        RodiLogger.info("Clarity session callback registered success=\(didRegisterSessionCallback)")
    }

    private static var isEnabled: Bool {
        let configuredValue = Bundle.main.rodiConfigurationString(for: "CLARITY_ENABLED")
        return ["1", "true", "yes"].contains(configuredValue.lowercased())
    }

    private static var projectID: String {
        Bundle.main.rodiConfigurationString(for: "CLARITY_PROJECT_ID")
    }

    private static var logLevel: ClarityLogLevel {
        switch Bundle.main.rodiConfigurationString(for: "CLARITY_LOG_LEVEL").lowercased() {
        case "verbose": .verbose
        case "debug": .debug
        case "info": .info
        case "warning": .warning
        case "error": .error
        default: .none
        }
    }

    private static var environment: String {
        Bundle.main.rodiConfigurationString(for: "RODI_ENVIRONMENT")
    }
}
