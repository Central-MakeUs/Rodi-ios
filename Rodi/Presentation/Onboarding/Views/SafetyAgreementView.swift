//
//  SafetyAgreementView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct SafetyAgreementView: View {
    let agreedSafetyItems: Set<SafetyAgreement>
    let isAllAgreed: Bool
    let onToggleSafety: (SafetyAgreement) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image("ic_caution_round")
                .resizable()
                .frame(width: 60, height: 60)
                .accessibilityHidden(true)
                .padding(.top, 96)

            Text("운전 자격 및 주의 사항")
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)
                .padding(.top, 32)

            Text("안전한 연습을 위해 아래 내용을 반드시 확인해 주세요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray800)
                .padding(.top, 8)

            SafetyNotice()
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 20) {
                ForEach(SafetyAgreement.allCases) { item in
                    SafetyCheckRow(
                        text: item.text,
                        isChecked: agreedSafetyItems.contains(item),
                        onToggle: { onToggleSafety(item) }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            PrimaryBottomButton(
                title: "다음",
                isEnabled: isAllAgreed,
                showsDivider: true,
                action: onNext
            )

        }
    }
}
