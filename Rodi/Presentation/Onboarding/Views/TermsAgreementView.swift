//
//  TermsAgreementView.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import SwiftUI

struct TermsAgreementView: View {
    private enum Constants {
        /// Status bar safe area(약 44pt) 이후 52pt를 더해 제목 시작점을 화면 상단 약 96pt에 맞춘다.
        static let titleTopInset: CGFloat = 52
    }

    let agreedTerms: Set<TermsAgreement>
    let isAllAgreed: Bool
    let onToggleAll: () -> Void
    let onToggleTerms: (TermsAgreement) -> Void
    let onOpenTerms: (TermsAgreement) -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("로디 서비스 시작하기")
                    .rodiTypography(.heading2)
                    .foregroundStyle(RodiColor.black)

                Text("아래 약관에 동의해주세요")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, Constants.titleTopInset)

            Button {
                onToggleAll()
            } label: {
                HStack(spacing: 8) {
                    CheckIcon(isActive: isAllAgreed)
                    Text("약관 전체 동의")
                        .rodiTypography(.body1Medium)
                        .foregroundStyle(RodiColor.black)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isAllAgreed ? RodiColor.gray900 : RodiColor.gray300, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 34)

            VStack(spacing: 20) {
                ForEach(TermsAgreement.allCases) { terms in
                    TermsRow(
                        title: terms.title,
                        isChecked: agreedTerms.contains(terms),
                        onCheck: { onToggleTerms(terms) },
                        onOpen: { onOpenTerms(terms) }
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Spacer()

            PrimaryBottomButton(title: "다음", isEnabled: isAllAgreed, action: onNext)
        }
    }
}
