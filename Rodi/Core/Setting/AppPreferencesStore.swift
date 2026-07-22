//
//  AppPreferencesStore.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import Foundation

struct AppPreferencesStore {
    private enum Key {
        static let hasSeenOnboarding = "rodi.preferences.hasSeenOnboarding"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func hasSeenOnboarding() -> Bool {
        userDefaults.bool(forKey: Key.hasSeenOnboarding)
    }

    func markOnboardingSeen() {
        userDefaults.set(true, forKey: Key.hasSeenOnboarding)
    }

    func resetOnboardingSeen() {
        userDefaults.set(false, forKey: Key.hasSeenOnboarding)
    }
}
