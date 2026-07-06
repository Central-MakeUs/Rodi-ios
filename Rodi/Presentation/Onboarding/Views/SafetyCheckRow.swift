//
//  SafetyCheckRow.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SafetyCheckRow: View {
    let text: String
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 8) {
                CheckIcon(isActive: isChecked)
                    .padding(.top, 1)

                Text(text)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(isChecked ? RodiColor.black : RodiColor.gray700)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityValue(isChecked ? "선택됨" : "선택 안 됨")
    }
}
