//
//  HomeChips.swift
//  Rodi
//

import SwiftUI

struct DifficultyChip: View {
    let score: Int
    let title: String

    var body: some View {
        Text(title)
            .rodiTypography(.caption3Medium)
            .foregroundStyle(RodiColor.gray800)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private var background: Color {
        switch score {
        case ...1:
            RodiColor.tagEasy
        case 2...3:
            RodiColor.tagMedium
        default:
            RodiColor.tagHard
        }
    }
}

struct TagChip: View {
    let title: String

    var body: some View {
        Text(title)
            .rodiTypography(.caption3Medium)
            .foregroundStyle(RodiColor.gray700)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RodiColor.gray200)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
