//
//  OnboardingEntryView.swift
//  Rodi
//

import SwiftUI

struct OnboardingEntryView: View {
    let state: OnboardingEntryReducer.State
    let send: (OnboardingEntryReducer.Action) -> Void

    private enum Constants {
        static let horizontalInset: CGFloat = 16
        static let browseTopInset: CGFloat = 12
        static let browseHorizontalInset: CGFloat = 12
        static let socialButtonHeight: CGFloat = 52
        static let socialButtonCornerRadius: CGFloat = 8
        static let socialButtonSpacing: CGFloat = 12
        static let socialButtonBottomInset: CGFloat = 40
        // TODO: UIScreen.main 이거 deprecated (윤수)
        static let recentLoginTooltipWidth = UIScreen.main.bounds.width * 0.35
    }

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()

            VStack() {
                browseRow
                Spacer()
                brandBlock
                Spacer()
                socialLoginButtons
            }

            if state.isAuthenticating {
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
            
            Button {
                send(.browseTapped)
            } label: {
                Text("둘러보기")
                    .font(.pretendard(size: 12, weight: .semibold))
                    .tracking(-0.24)
                    .foregroundStyle(RodiColor.gray500)
                    .padding(.horizontal, Constants.browseHorizontalInset)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(state.isAuthenticating)
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
        VStack(spacing: 0) {
            if state.recentLoginProvider != nil {
                Image("img_resent_login_tooltip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.recentLoginTooltipWidth)
                    .frame(maxWidth: .infinity)
            }

            VStack(spacing: Constants.socialButtonSpacing) {
                ForEach(state.socialProviders, id: \.rawValue) { provider in
                    socialButton(provider)
                }
            }
        }
        .padding(.horizontal, Constants.horizontalInset)
        .padding(.bottom, Constants.socialButtonBottomInset)
    }

    @ViewBuilder
    private func socialButton(_ provider: SocialLoginProvider) -> some View {
        switch provider {
            case .kakao:
                SocialLoginButton(
                    title: "카카오로 시작하기",
                    assetName: "ic_login_kakao",
                    backgroundColor: Color(hex: 0xFDE500),
                    foregroundColor: RodiColor.black,
                    action: {
                        send(.onKakaoLoginTapped)
                    }
                )

            case .apple:
                SocialLoginButton(
                    title: "Apple ID로 시작하기",
                    assetName: "ic_login_apple",
                    backgroundColor: RodiColor.black,
                    foregroundColor: RodiColor.white,
                    action: {
                        send(.onAppleLoginTapped)
                    }
                )
        }
    }
}
