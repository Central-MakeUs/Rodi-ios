//
//  DualBottomButton.swift
//  Rodi
//

import SwiftUI

struct DualBottomButton: View {
    let secondaryTitle: String
    let primaryTitle: String
    let isPrimaryEnabled: Bool
    let secondaryAction: () -> Void
    let primaryAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let spacing: CGFloat = 6
                let availableWidth = max(proxy.size.width - spacing, 0)
                let secondaryWidth = availableWidth * 0.4
                let primaryWidth = availableWidth * 0.6

                HStack(spacing: spacing) {
                    Button(action: secondaryAction) {
                        Text(secondaryTitle)
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(RodiColor.gray800)
                            .frame(width: secondaryWidth, height: 46)
                            .background(RodiColor.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RodiColor.gray300, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)

                    Button(action: primaryAction) {
                        Text(primaryTitle)
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(isPrimaryEnabled ? RodiColor.white : RodiColor.gray500)
                            .frame(width: primaryWidth, height: 46)
                            .background(isPrimaryEnabled ? RodiColor.primary : RodiColor.gray300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isPrimaryEnabled)
                }
            }
            .frame(height: 46)
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .background(RodiColor.white)
    }
}
