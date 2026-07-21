//
//  RodiDesignSystem.swift
//  Rodi
//
//  Created by Codex on 6/27/26.
//

import SwiftUI

enum RodiColor {
    static let primary = Color(hex: 0x5640FF)
    static let primary20 = Color(hex: 0xF4F4FF)
    static let primary50 = Color(hex: 0xF0EFFF)
    static let primary100 = Color(hex: 0xDBD9FF)
    static let primaryMinus100 = Color(hex: 0xF5F5F0)
    static let primary200 = Color(hex: 0xBAB6FF)
    static let primary400 = Color(hex: 0x7062FF)
    static let black = Color(hex: 0x222222)
    static let white = Color.white
    static let tagEasy = Color(hex: 0xCDF2F6)
    static let tagMedium = Color(hex: 0xFFF0C2)
    static let tagHard = Color(hex: 0xFFD6D6)
    static let gray50 = Color(hex: 0xFAFAFA)
    static let gray100 = Color(hex: 0xF5F5F5)
    static let gray200 = Color(hex: 0xEFEFEF)
    static let gray900 = Color(hex: 0x222222)
    static let gray850 = Color(hex: 0x323232)
    static let gray800 = Color(hex: 0x434343)
    static let gray700 = Color(hex: 0x626262)
    static let gray600 = Color(hex: 0x767676)
    static let gray500 = Color(hex: 0x9F9F9F)
    static let gray400 = Color(hex: 0xC6C8CB)
    static let gray300 = Color(hex: 0xE1E1E1)
}

enum RodiTypography {
    case heading2
    case headline1
    case headline2
    case body1SemiBold
    case body1Medium
    case body3Medium
    case caption1Medium
    case caption1Regular
    case caption2Medium
    case caption2SemiBold
    case caption3Medium
    case buttonMedium

    var font: Font {
        .custom(fontName, size: size)
    }

    var tracking: CGFloat {
        size * -0.02
    }

    var lineSpacing: CGFloat {
        switch self {
        case .buttonMedium:
            size * 0.4 - size * 0.3
        default:
            1
        }
    }

    private var size: CGFloat {
        switch self {
        case .heading2:
            20
        case .headline1:
            18
        case .headline2:
            17
        case .body1SemiBold, .body1Medium, .buttonMedium:
            16
        case .body3Medium:
            14
        case .caption1Medium, .caption1Regular:
            13
        case .caption2Medium, .caption2SemiBold:
            12
        case .caption3Medium:
            10
        }
    }

    private var fontName: String {
        switch self {
        case .heading2, .headline1, .headline2:
            "Pretendard-Bold"
        case .body1SemiBold, .caption2SemiBold:
            "Pretendard-SemiBold"
        case .caption1Regular:
            "Pretendard-Regular"
        case .body1Medium, .body3Medium, .caption1Medium, .caption2Medium, .caption3Medium, .buttonMedium:
            "Pretendard-Medium"
        }
    }
}

extension Text {
    func rodiTypography(_ typography: RodiTypography) -> some View {
        self
            .font(typography.font)
            .tracking(typography.tracking)
            .lineSpacing(typography.lineSpacing)
    }
}

extension Font {
    static func pretendard(size: CGFloat, weight: RodiFontWeight = .regular) -> Font {
        .custom(RodiFontWeight.fontName(for: weight), size: size)
    }
}

extension UIFont {
    static func pretendard(size: CGFloat, weight: RodiFontWeight = .regular) -> UIFont {
        UIFont(name: RodiFontWeight.fontName(for: weight), size: size)
            ?? .systemFont(ofSize: size, weight: weight.uiFontWeight)
    }
}

enum RodiFontWeight {
    case regular
    case medium
    case semibold
    case bold

    static func fontName(for weight: RodiFontWeight) -> String {
        switch weight {
        case .bold:
            "Pretendard-Bold"
        case .semibold:
            "Pretendard-SemiBold"
        case .regular:
            "Pretendard-Regular"
        case .medium:
            "Pretendard-Medium"
        }
    }

    var uiFontWeight: UIFont.Weight {
        switch self {
        case .regular:
            .regular
        case .medium:
            .medium
        case .semibold:
            .semibold
        case .bold:
            .bold
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
