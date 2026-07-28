//
//  LoginRequiredDialog.swift
//  Rodi
//

import SwiftUI

struct LoginRequiredDialog: View {
    let dismissAction: () -> Void
    let kakaoLoginAction: () -> Void
    let appleLoginAction: () -> Void

    var body: some View {
        Color.black
            .opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 36)

                    Spacer(minLength: 0)
                        .frame(height: 81)

                    Text("로그인 후\n이용 가능한 기능이에요.")
                        .font(.pretendard(size: 18, weight: .bold))
                        .tracking(-0.36)
                        .foregroundStyle(RodiColor.gray800)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)

                    Spacer(minLength: 0)
                        .frame(height: 88)

                    socialButton(
                        title: "카카오로 시작하기",
                        assetName: "ic_login_kakao",
                        background: Color(hex: 0xFDE500),
                        foreground: RodiColor.black,
                        action: kakaoLoginAction
                    )
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)
                        .frame(height: 12)

                    socialButton(
                        title: "Apple ID로 시작하기",
                        assetName: "ic_login_apple",
                        background: RodiColor.black,
                        foreground: RodiColor.white,
                        action: appleLoginAction
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .frame(width: 290, height: 404)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    Button(action: dismissAction) {
                        Image(systemName: "xmark")
                            .font(.pretendard(size: 16, weight: .medium))
                            .foregroundStyle(RodiColor.black)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("닫기")
                    .padding(.top, 16)
                    .padding(.trailing, 16)
                }
            }
            .accessibilityElement(children: .contain)
    }

    private func socialButton(
        title: String,
        assetName: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)

                Text(title)
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
