//
//  OnboardingChip.swift
//  Rodi
//

import SwiftUI

struct OnboardingSection<Content: View>: View {
    let title: String
    var trailing: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(title)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)

                if let trailing {
                    Text(trailing)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)
                }
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
