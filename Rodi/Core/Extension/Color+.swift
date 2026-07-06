//
//  Color+.swift
//  MiniHack
//
//  Created by mac on 5/15/26.
//

import SwiftUI

extension Color {
    init(hexCode: String, alpha: CGFloat = 1.0) {
        var hexFormatted = hexCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        assert(hexFormatted.count == 6, "Invalid hex code used.")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        self.init(
            .sRGB,
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0,
            opacity: Double(alpha)
        )
    }
}
