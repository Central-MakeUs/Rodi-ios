//
//  FirebaseAnalyticsConfiguration.swift
//  Rodi
//

import FirebaseAnalytics
import Foundation

enum FirebaseAnalyticsConfiguration {

    static func applyCollectionPolicy() {
        let rawValue = Bundle.main.rodiConfigurationString(for: "RODI_ANALYTICS_ENABLED")
        let isEnabled = ["1", "true", "yes"].contains(rawValue.lowercased())
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
        RodiLogger.info("Firebase Analytics collection configured enabled=\(isEnabled)")
    }
}
