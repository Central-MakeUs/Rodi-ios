//
//  OnboardingEntryView.swift
//  Rodi
//

import SwiftUI

struct OnboardingEntryView: View {
    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let browseTopInset: CGFloat = 12
        static let browseHorizontalInset: CGFloat = 12
        static let socialButtonHeight: CGFloat = 52
        static let socialButtonCornerRadius: CGFloat = 8
        static let socialButtonSpacing: CGFloat = 12
        static let socialButtonBottomInset: CGFloat = 40
    }

    let isAuthenticating: Bool
    let onBrowse: () -> Void
    let onAppleLogin: () -> Void
    let onKakaoLogin: () -> Void

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()

            VStack(spacing: 0) {
                browseRow

                Spacer(minLength: 0)

                brandBlock

                Spacer(minLength: 0)

                socialLoginButtons
            }

            if isAuthenticating {
                ProgressView()
                    .tint(RodiColor.primary)
                    .padding(18)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("로그인 중")
            }
        }
    }

    private var browseRow: some View {
        HStack {
            Spacer()

            Button(action: onBrowse) {
                Text("둘러보기")
                    .font(.pretendard(size: 12, weight: .semibold))
                    .tracking(-0.24)
                    .foregroundStyle(RodiColor.gray500)
                    .padding(.horizontal, Constants.browseHorizontalInset)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(isAuthenticating)
        }
        .padding(.top, Constants.browseTopInset)
        .padding(.trailing, 4)
    }

    private var brandBlock: some View {
        VStack(spacing: 8) {
            Image("img_rodi_login_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 146, height: 45)
                .accessibilityLabel("RODI")

            Text("운전연습의 시작, 로디")
                .font(.pretendard(size: 16, weight: .medium))
                .tracking(-0.32)
                .foregroundStyle(RodiColor.black)
        }
        .frame(maxWidth: .infinity)
    }

    private var socialLoginButtons: some View {
        VStack(spacing: Constants.socialButtonSpacing) {
            socialButton(
                title: "카카오로 시작하기",
                assetName: "ic_login_kakao",
                background: Color(hex: 0xFDE500),
                foreground: RodiColor.black,
                action: onKakaoLogin
            )

            socialButton(
                title: "Apple ID로 시작하기",
                assetName: "ic_login_apple",
                background: RodiColor.black,
                foreground: RodiColor.white,
                action: onAppleLogin
            )
        }
        .padding(.horizontal, Constants.horizontalInset)
        .padding(.bottom, Constants.socialButtonBottomInset)
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
            .frame(height: Constants.socialButtonHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Constants.socialButtonCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isAuthenticating)
        .accessibilityLabel(title)
    }
}
