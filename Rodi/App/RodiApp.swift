//
//  RodiApp.swift
//  Rodi
//
//  Created by mac on 6/26/26.
//

import SwiftUI

#if canImport(KakaoSDKCommon)
import KakaoSDKCommon
#endif

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK
#endif

@main
struct RodiApp: App {
    init() {
        RodiLogger.configure()
        RodiFontRegistrar.registerFonts()
        RodiLogger.info(
            "Kakao key state native=\(RodiLogger.masked(KakaoConfiguration.nativeAppKey)), rest=\(RodiLogger.masked(KakaoConfiguration.restAPIKey))"
        )

        if KakaoConfiguration.hasNativeAppKey {
            #if canImport(KakaoSDKCommon)
            KakaoSDK.initSDK(appKey: KakaoConfiguration.nativeAppKey)
            RodiLogger.info("Kakao iOS SDK initializer called")
            #endif

            #if canImport(KakaoMapsSDK)
            SDKInitializer.InitSDK(appKey: KakaoConfiguration.nativeAppKey)
            RodiLogger.info("KakaoMapsSDK initializer called")
            #endif
        } else {
            RodiLogger.error("Kakao SDK initializer skipped: native app key is empty")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
