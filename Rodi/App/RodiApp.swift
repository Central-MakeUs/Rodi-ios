//
//  RodiApp.swift
//  Rodi
//
//  Created by mac on 6/26/26.
//

import SwiftUI
import KakaoSDKCommon
import KakaoMapsSDK

@main
struct RodiApp: App {

    init() {
        RodiLogger.configure()
        RodiFontRegistrar.registerFonts()

        switch KakaoConfiguration.hasNativeAppKey {
            case true:
                KakaoSDK.initSDK(appKey: KakaoConfiguration.nativeAppKey)
                SDKInitializer.InitSDK(appKey: KakaoConfiguration.nativeAppKey)

            case false:
                RodiLogger.error("Kakao SDK initializer skipped: native app key is empty")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
