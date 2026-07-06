//
//  KakaoConfiguration.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import Foundation

enum KakaoConfiguration {
    static var nativeAppKey: String {
        Bundle.main.rodiString(for: "KAKAO_NATIVE_APP_KEY")
    }

    static var restAPIKey: String {
        Bundle.main.rodiString(for: "KAKAO_REST_API_KEY")
    }

    static var hasNativeAppKey: Bool {
        !nativeAppKey.isEmpty
    }
}

private extension Bundle {
    func rodiString(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String else { return "" }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("$(") ? "" : trimmed
    }
}
