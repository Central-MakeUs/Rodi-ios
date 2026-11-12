//
//  AppLifecycleDelegate.swift
//  Rodi
//

import Clarity
import FirebaseAnalytics
import FirebaseCore
import UIKit

final class AppLifecycleDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseAnalyticsConfiguration.applyCollectionPolicy()
        ClarityConfiguration.initializeIfEnabled()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        guard #available(iOS 16.1, *) else { return }
        PracticeLiveActivityService.endAllBeforeProcessTermination()
    }
}
