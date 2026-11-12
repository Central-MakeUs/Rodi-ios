//
//  KakaoConfiguration.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import Foundation
import KakaoSDKCommon
import KakaoMapsSDK

enum KakaoConfiguration {
    private static var didInitializeSDK = false

    static var nativeAppKey: String {
        Bundle.main.rodiString(for: "KAKAO_NATIVE_APP_KEY")
    }

    static var restAPIKey: String {
        Bundle.main.rodiString(for: "KAKAO_REST_API_KEY")
    }

    static var hasNativeAppKey: Bool {
        !nativeAppKey.isEmpty
    }

    static func initializeSDK() {
        guard hasNativeAppKey else {
            RodiLogger.error("Kakao SDK initializer skipped: native app key is empty")
            return
        }

        guard !didInitializeSDK else { return }

        KakaoSDK.initSDK(appKey: nativeAppKey)
        SDKInitializer.InitSDK(appKey: nativeAppKey)
        didInitializeSDK = true
    }
}

private extension Bundle {
    func rodiString(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return "" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
