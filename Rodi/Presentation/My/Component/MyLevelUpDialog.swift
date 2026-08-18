//
//  MyLevelUpDialog.swift
//  Rodi
//

import SwiftUI

struct MyLevelUpDialog: View {
    let level: MemberProfile.Level
    let confirm: () -> Void

    var body: some View {
        RodiModalBackground {
            VStack(spacing: 0) {
                Text("Level Up!")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                Text("레벨업 했어요,\n앞으로도 새로운 코스에 도전해보세요!")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.black)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                RodiLevelProfileImage(
                    level: level,
                    size: 150,
                    imageOffsetY: 0
                )
                .padding(.top, 14)

                Text(level.displayName)
                    .rodiTypography(.body1Medium)
                    .foregroundStyle(RodiColor.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [RodiColor.primary100, RodiColor.primary200],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.top, 14)

                Button(action: confirm) {
                    Text("확인")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(RodiColor.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .background(RodiColor.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .accessibilityLabel("레벨업 확인")
                .padding(.top, 12)
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(width: 290)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityElement(children: .contain)
    }
}
