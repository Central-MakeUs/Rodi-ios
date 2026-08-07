//
//  EnvironmentValues+ScreenBounds.swift
//  Rodi
//

import SwiftUI
import UIKit

@MainActor
private enum ScreenWindow {
    static var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        return scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first
    }

    static var keyWindow: UIWindow? {
        activeWindowScene?
            .windows
            .first(where: { $0.isKeyWindow })
            ?? activeWindowScene?.windows.first
    }

    static var bounds: CGRect {
        keyWindow?.screen.bounds
            ?? activeWindowScene?.screen.bounds
            ?? UIScreen.main.bounds
    }
}

@MainActor
private struct ScreenBoundsKey: @preconcurrency EnvironmentKey {
    static var defaultValue: CGRect? {
        ScreenWindow.bounds
    }
}

@MainActor
private struct ScreenSafeAreaInsetsKey: @preconcurrency EnvironmentKey {
    static var defaultValue: EdgeInsets {
        let insets = ScreenWindow.keyWindow?.safeAreaInsets ?? .zero
        return EdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right
        )
    }
}

extension EnvironmentValues {
    var screenBounds: CGRect? {
        self[ScreenBoundsKey.self]
    }

    var screenSafeAreaInsets: EdgeInsets {
        self[ScreenSafeAreaInsetsKey.self]
    }
}
