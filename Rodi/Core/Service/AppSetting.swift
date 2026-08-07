//
//  AppSetting.swift
//  Rodi
//
//  Created by mac on 8/4/26.
//

import UIKit

@MainActor
final class AppSettings {
    
    static func openSetting() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
