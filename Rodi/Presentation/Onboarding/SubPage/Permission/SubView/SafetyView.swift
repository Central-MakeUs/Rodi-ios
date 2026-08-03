//
//  SafetyView.swift
//  Rodi
//

import SwiftUI

struct SafetyView: View {
    let state: OnboardingPermissionReducer.State
    let send: (OnboardingPermissionReducer.Action) -> Void

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
                        item: item,
                        isChecked: state.agreedSafetyItems.contains(item),
                        onToggle: { send(.toggleSafety(item)) }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            Spacer()

            PrimaryBottomButton(
                title: "다음",
                isEnabled: state.isAllSafetyAgreed,
                showsDivider: true,
                action: { send(.safetyNextTapped) }
            )
        }
    }
}

private struct SafetyCheckRow: View {
    let item: SafetyAgreement
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 8) {
                CheckIcon(isActive: isChecked)
                    .padding(.top, 1)

                Text(item.text)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(isChecked ? RodiColor.black : RodiColor.gray700)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.text)
        .accessibilityValue(isChecked ? "선택됨" : "선택 안 됨")
    }
}

private struct SafetyNotice: View {
    var body: some View {
        Text(attributedNotice)
            .rodiTypography(.caption1Medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RodiColor.primary20)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var attributedNotice: AttributedString {
        var text = AttributedString("로디는 사고가 나지 않는 장소를 보장하지 않습니다.\n연습에 적합한 장소를 추천 드리더라도, 도로 위에서 발생하는\n모든 사고의 책임은 운전자 본인에게 있습니다.\n항상 교통 법규를 준수하고, 안전을 최우선으로 생각해 주세요.")
        text.foregroundColor = RodiColor.gray800

        if let range = text.range(of: "사고가 나지 않는 장소를 보장하지 않습니다.") {
            text[range].foregroundColor = RodiColor.primary
        }

        if let range = text.range(of: "모든 사고의 책임은 운전자 본인에게 있습니다.") {
            text[range].foregroundColor = RodiColor.primary
        }

        return text
    }
}
