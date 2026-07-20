//
//  MyView.swift
//  Rodi
//

import SwiftUI

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

/// 마이 탭은 약관, 문의, 세션 관리 항목을 직접 소유한다.
struct MyView: View {
    let tabBar: RodiBottomTabBar
    let authRepository: AuthRepository
    let memberRepository: MemberRepository
    let onLogout: () -> Void

    init(
        tabBar: RodiBottomTabBar,
        authRepository: AuthRepository = AuthDependencyContainer.shared.authRepository,
        memberRepository: MemberRepository = AuthDependencyContainer.shared.memberRepository,
        onLogout: @escaping () -> Void
    ) {
        self.tabBar = tabBar
        self.authRepository = authRepository
        self.memberRepository = memberRepository
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LegalSettingsView(
                title: "마이",
                logoutAction: performLogout,
                withdrawalAction: performWithdrawal
            )

            tabBar
        }
    }

    private func performLogout() {
        Task {
            do {
                try await authRepository.logout()
                RodiLogger.info("Logout API completed")
            } catch {
                authRepository.clearSession()
                RodiLogger.warning("Logout API failed; local session cleared. error=\(error)")
            }

            await logoutKakaoSDKSessionIfNeeded()
            onLogout()
        }
    }

    private func performWithdrawal() {
        Task {
            do {
                try await memberRepository.withdraw()
                RodiLogger.info("Member withdrawal API completed")
            } catch {
                RodiLogger.warning("Member withdrawal API failed. error=\(error)")
                return
            }

            authRepository.clearSession()
            await logoutKakaoSDKSessionIfNeeded()
            onLogout()
        }
    }

    private func logoutKakaoSDKSessionIfNeeded() async {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { error in
                if let error {
                    RodiLogger.warning("Kakao SDK logout failed or no active Kakao session. error=\(error)")
                } else {
                    RodiLogger.info("Kakao SDK logout completed")
                }
                continuation.resume()
            }
        }
        #endif
    }
}
