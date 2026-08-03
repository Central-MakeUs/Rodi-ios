//
//  RodiFontRegistrar.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import CoreText
import Foundation
import UIKit

enum RodiFontRegistrar {
    private static let fontFileNames = [
        "Pretendard-Regular",
        "Pretendard-Medium",
        "Pretendard-SemiBold",
        "Pretendard-Bold"
    ]

    static func registerFonts() {
        fontFileNames.forEach { fileName in
            registerFont(named: fileName)
        }
    }

    private static func registerFont(named fileName: String) {
        if UIFont(name: fileName, size: 12) != nil {
            RodiLogger.debug("Pretendard font available: \(fileName)")
            return
        }

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "otf", subdirectory: "Resources/Fonts")
            ?? Bundle.main.url(forResource: fileName, withExtension: "otf")
        else {
            RodiLogger.warning("Pretendard font file missing: \(fileName).otf")
            return
        }

        var error: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if didRegister {
            RodiLogger.debug("Pretendard font registered: \(fileName)")
            return
        }

        guard let error else {
            RodiLogger.warning("Pretendard font registration failed: \(fileName)")
            return
        }

        let nsError = error.takeRetainedValue() as Error as NSError
        if nsError.domain == kCTFontManagerErrorDomain as String,
           nsError.code == CTFontManagerError.alreadyRegistered.rawValue {
            RodiLogger.debug("Pretendard font already registered: \(fileName)")
        } else {
            RodiLogger.warning("Pretendard font registration failed: \(fileName), error=\(nsError.localizedDescription)")
        }
    }
}
