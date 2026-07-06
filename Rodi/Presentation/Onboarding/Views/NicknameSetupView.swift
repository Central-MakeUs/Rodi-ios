//
//  NicknameSetupView.swift
//  Rodi
//

import SwiftUI

struct NicknameSetupView: View {
    let nickname: String
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("닉네임")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                HStack(spacing: 4) {
                    Text("‘")
                    Text(nickname)
                    Text("’")
                }
                .font(.pretendard(size: 22, weight: .bold))
                .tracking(-0.264)
                .foregroundStyle(RodiColor.primary)

                Text("로 시작해요.")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -56)

            Spacer()

            PrimaryBottomButton(title: "다음", isEnabled: true, action: onNext)
        }
    }
}
