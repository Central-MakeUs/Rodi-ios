//
//  FirebaseAnalyticsTracker.swift
//  Rodi
//

import FirebaseAnalytics
import Foundation

/// Firebase Analytics SDK 호출을 Core 기술 경계에 한정하는 adapter입니다.
enum FirebaseAnalyticsTracker {
    static func track(name: String, parameters: [String: Any]) {
        Analytics.logEvent(name, parameters: parameters)
    }

    static func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
