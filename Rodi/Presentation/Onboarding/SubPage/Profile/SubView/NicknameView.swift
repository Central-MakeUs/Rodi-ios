//
//  NicknameView.swift
//  Rodi
//

import SwiftUI

struct NicknameView: View {
    let state: OnboardingProfileReducer.State
    let send: (OnboardingProfileReducer.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("닉네임")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                if state.nickname.isEmpty {
                    Text("닉네임 정보를 불러오지 못했어요.")
                        .rodiTypography(.body1Medium)
                        .foregroundStyle(RodiColor.gray700)
                } else {
                    HStack(spacing: 4) {
                        Text("‘")
                        Text(state.nickname)
                        Text("’")
                    }
                    .font(.pretendard(size: 22, weight: .bold))
                    .tracking(-0.264)
                    .foregroundStyle(RodiColor.primary)

                    Text("로 시작해요.")
                        .rodiTypography(.headline1)
                        .foregroundStyle(RodiColor.black)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -56)

            Spacer()

            PrimaryBottomButton(
                title: "다음",
                isEnabled: state.canProceedFromNickname,
                showsDivider: true,
                action: { send(.nicknameNextTapped) }
            )
        }
    }
}
