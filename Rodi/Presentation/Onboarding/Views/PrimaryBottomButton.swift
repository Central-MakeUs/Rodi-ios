//
//  PrimaryBottomButton.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct PrimaryBottomButton: View {
    let title: String
    let isEnabled: Bool
    var showsDivider = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showsDivider {
                Rectangle()
                    .fill(RodiColor.gray200)
                    .frame(height: 1)
            }

            Button(action: action) {
                Text(title)
                    .rodiTypography(.buttonMedium)
                    .foregroundStyle(isEnabled ? RodiColor.white : RodiColor.gray500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(isEnabled ? RodiColor.primary : RodiColor.gray300)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!isEnabled)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(RodiColor.white)
    }
}
