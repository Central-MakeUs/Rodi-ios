//
//  RodiCrashReporter.swift
//  Rodi
//

import FirebaseCrashlytics
import Foundation

/// 개인 식별값 없이 예상하지 못한 기술 실패만 Crashlytics에 남긴다.
enum RodiCrashReporter {

    static func record(
        _ error: Error,
        endpointCategory: String? = nil,
        statusFamily: String? = nil
    ) {
        let crashlytics = Crashlytics.crashlytics()

        if let endpointCategory {
            crashlytics.setCustomValue(endpointCategory, forKey: "endpoint_category")
        }
        if let statusFamily {
            crashlytics.setCustomValue(statusFamily, forKey: "http_status_family")
        }

        crashlytics.record(error: error)
    }

    static func record(
        message: String,
        endpointCategory: String? = nil,
        statusFamily: String? = nil
    ) {
        record(
            NSError(
                domain: "com.dororong.rodi",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: message]
            ),
            endpointCategory: endpointCategory,
            statusFamily: statusFamily
        )
    }
}
