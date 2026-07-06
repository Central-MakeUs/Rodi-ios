//
//  OnboardingEntryView.swift
//  Rodi
//

import SwiftUI

struct OnboardingEntryView: View {
    let isAuthenticating: Bool
    let onBrowse: () -> Void
    let onAppleLogin: () -> Void
    let onKakaoLogin: () -> Void

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("둘러보기", action: onBrowse)
                        .font(.pretendard(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: 0xBDC4C8))
                        .disabled(isAuthenticating)
                }
                .padding(.horizontal, 28)

                Spacer()

                VStack(spacing: 10) {
                    Text("RODI")
                        .font(.custom("Pretendard-Bold", size: 56))
                        .italic()
                        .tracking(-1.24)
                        .foregroundStyle(Color(hex: 0x252525))

                    Text("나에게 맞는 운전 연습 코스 탐색의 시작, Rodi")
                        .font(.pretendard(size: 16, weight: .regular))
                        .tracking(-1.24)
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.center)
                }
                .offset(y: -28)

                Spacer()

                VStack(spacing: 12) {
                    socialButton(
                        title: "Apple로 시작하기",
                        systemImage: "applelogo",
                        background: Color(hex: 0x101419),
                        foreground: RodiColor.white,
                        action: onAppleLogin
                    )

                    socialButton(
                        title: "카카오로 시작하기",
                        systemImage: "message.fill",
                        background: Color(hex: 0xFAE100),
                        foreground: Color.black,
                        action: onKakaoLogin
                    )
                }
                .padding(.horizontal, 38)
                .padding(.bottom, 25)
            }

            if isAuthenticating {
                ProgressView()
                    .tint(RodiColor.primary)
                    .padding(18)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func socialButton(
        title: String,
        systemImage: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.pretendard(size: 15, weight: .regular))
                    .tracking(-0.3)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(background)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isAuthenticating)
    }
}
