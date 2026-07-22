//
//  TermsRow.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct TermsRow: View {
    let title: String
    let isChecked: Bool
    let onCheck: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onCheck) {
                CheckIcon(isActive: isChecked)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("약관 선택: \(title)")
            .accessibilityValue(isChecked ? "선택됨" : "선택 안 됨")

            Button(action: onOpen) {
                HStack {
                    Text(title)
                        .rodiTypography(.body1Medium)
                        .foregroundStyle(RodiColor.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.pretendard(size: 13, weight: .medium))
                        .foregroundStyle(RodiColor.gray600)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }
}
