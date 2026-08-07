//
//  LoginView.swift
//  Rodi
//

import SwiftUI

struct LoginView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: StoreOf<LoginReducer>
    @State private var consumedCommandID: UUID?
    @State private var didLeaveForKakaoLogin = false

    private let command: LoginCommand?
    private let onTransition: (OnboardingTransition) -> Void

    init(
        session: OnboardingSession,
        command: LoginCommand?,
        onTransition: @escaping (OnboardingTransition) -> Void,
        authRepository: AuthRepository,
        recentLoginProviderStore: RecentLoginProviderStore,
        socialLoginService: SocialLoginService
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: .init(
                    session: session,
                    recentLoginProvider: recentLoginProviderStore.load()
                ),
                reducer: LoginReducer(
                    authRepository: authRepository,
                    socialLoginService: socialLoginService
                )
            )
        )
        self.command = command
        self.onTransition = onTransition
    }

    var body: some View {
        ZStack {
            RodiColor.white.ignoresSafeArea()
            VStack {
                browseRow
                Spacer()
                brandBlock
                Spacer()
                socialLoginButtons
            }

            if store.state.isAuthenticating {
                ProgressView()
                    .tint(RodiColor.primary)
                    .padding(18)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("로그인 중")
            }
        }
        .onOpenURL { store.send(.openedURL($0)) }
        .onChange(of: scenePhase) { phase in
            handleKakaoLoginScenePhase(phase)
        }
        .onAppear { consumeCommandIfNeeded() }
        .onChange(of: command) { _ in consumeCommandIfNeeded() }
        .onChange(of: store.state.transition) { transition in
            guard let transition else { return }
            onTransition(transition)
            store.send(.transitionConsumed)
        }
        .alert("로그인에 실패했어요", isPresented: loginFailureBinding) {
            Button("확인") { store.send(.dismissPresentation) }
        } message: {
            Text(loginFailureMessage)
        }
        .overlay { withdrawalOverlay }
    }
}

private extension LoginView {
    func send(_ action: LoginReducer.Action) {
        store.send(action)
    }

    func consumeCommandIfNeeded() {
        guard let command, consumedCommandID != command.id else { return }
        consumedCommandID = command.id
        switch command.kind {
        case .login(.kakao): send(.kakaoLoginTapped)
        case .login(.apple): send(.appleLoginTapped)
        case .restore(let recovery): send(.restoreTapped(recovery))
        }
    }

    func handleKakaoLoginScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .inactive, .background:
            guard store.state.isAuthenticating,
                  store.state.pendingAuthenticationProvider == .kakao
            else {
                return
            }
            didLeaveForKakaoLogin = true

        case .active:
            guard didLeaveForKakaoLogin else { return }
            didLeaveForKakaoLogin = false
            send(.kakaoLoginReturnDetected)

        @unknown default:
            break
        }
    }

    var loginFailureBinding: Binding<Bool> {
        .init(
            get: { if case .loginFailure = store.state.presentation { return true }; return false },
            set: { if !$0 { store.send(.dismissPresentation) } }
        )
    }

    var loginFailureMessage: String {
        if case .loginFailure(let message) = store.state.presentation { return message }
        return ""
    }

    @ViewBuilder
    var withdrawalOverlay: some View {
        if case .withdrawal(let state) = store.state.presentation {
            WithdrawalAccountDialog(
                state: state,
                restoreAction: {
                    if case .restore(let recovery) = state { send(.restoreTapped(recovery)) }
                },
                dismissAction: { send(.dismissPresentation) }
            )
        }
    }

    var browseRow: some View {
        HStack {
            Spacer()
            Button { send(.browseTapped) } label: {
                Text("둘러보기")
                    .font(.pretendard(size: 12, weight: .semibold))
                    .tracking(-0.24)
                    .foregroundStyle(RodiColor.gray500)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .disabled(store.state.isAuthenticating)
        }
        .padding(.top, 12)
        .padding(.trailing, 4)
    }

    var brandBlock: some View {
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

    var socialLoginButtons: some View {
        VStack(spacing: 0) {
            if store.state.recentLoginProvider != nil {
                Image("img_resent_login_tooltip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.main.bounds.width * 0.35)
                    .frame(maxWidth: .infinity)
            }
            VStack(spacing: 12) {
                ForEach(store.state.socialProviders, id: \.rawValue) { provider in
                    socialButton(provider)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    func socialButton(_ provider: SocialLoginProvider) -> some View {
        switch provider {
        case .kakao:
            SocialLoginButton(title: "카카오로 시작하기", assetName: "ic_login_kakao", backgroundColor: Color(hex: 0xFDE500), foregroundColor: RodiColor.black, action: { send(.kakaoLoginTapped) })
        case .apple:
            SocialLoginButton(title: "Apple ID로 시작하기", assetName: "ic_login_apple", backgroundColor: RodiColor.black, foregroundColor: RodiColor.white, action: { send(.appleLoginTapped) })
        }
    }
}
