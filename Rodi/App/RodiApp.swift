//
//  RodiApp.swift
//  Rodi
//
//  Created by mac on 6/26/26.
//

import SwiftUI

@main
struct RodiApp: App {

    @UIApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var appLifecycleDelegate

    init() {
        RodiLogger.configure()
        RodiFontRegistrar.registerFonts()

        KakaoConfiguration.initializeSDK()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
