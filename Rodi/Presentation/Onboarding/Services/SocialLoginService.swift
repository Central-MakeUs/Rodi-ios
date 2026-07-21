//
//  SocialLoginService.swift
//  Rodi
//

import AuthenticationServices
import Foundation
import UIKit

#if canImport(KakaoSDKAuth)
import KakaoSDKAuth
#endif

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

@MainActor
final class SocialLoginService: NSObject {
    private var appleContinuation: CheckedContinuation<Result<String, Error>, Never>?

    var isKakaoTalkLoginAvailable: Bool {
        #if canImport(KakaoSDKUser)
        UserApi.isKakaoTalkLoginAvailable()
        #else
        false
        #endif
    }

    func loginWithApple() async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            appleContinuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func loginWithKakaoTalk() async -> Result<String, Error> {
        await loginWithKakao { completion in
            UserApi.shared.loginWithKakaoTalk(completion: completion)
        }
    }

    func loginWithKakaoAccount() async -> Result<String, Error> {
        await loginWithKakao { completion in
            UserApi.shared.loginWithKakaoAccount(completion: completion)
        }
    }

    private func loginWithKakao(
        request: @escaping (@escaping (OAuthToken?, Error?) -> Void) -> Void
    ) async -> Result<String, Error> {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    continuation.resume(returning: .failure(error))
                } else if let accessToken = token?.accessToken, !accessToken.isEmpty {
                    #if DEBUG
                    RodiLogger.debug("Kakao access token for restore test: \(RodiLogger.masked(accessToken))")
                    #endif
                    continuation.resume(returning: .success(accessToken))
                } else {
                    continuation.resume(returning: .failure(SocialLoginError.emptyKakaoToken))
                }
            }

            request(completion)
        }
        #else
        .failure(SocialLoginError.kakaoSDKUnavailable)
        #endif
    }

    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(KakaoSDKAuth)
        guard AuthApi.isKakaoTalkLoginUrl(url) else { return false }
        return AuthController.handleOpenUrl(url: url)
        #else
        return false
        #endif
    }
}

extension SocialLoginService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                appleContinuation?.resume(returning: .failure(SocialLoginError.invalidAppleCredential))
                appleContinuation = nil
                return
            }

            guard let authorizationCode = credential.authorizationCode,
                  let code = String(data: authorizationCode, encoding: .utf8),
                  !code.isEmpty else {
                appleContinuation?.resume(returning: .failure(SocialLoginError.invalidAppleAuthorizationCode))
                appleContinuation = nil
                return
            }

            RodiLogger.info("Apple sign-in succeeded userID=\(RodiLogger.masked(credential.user))")
            #if DEBUG
            RodiLogger.debug("Apple authorization code for restore test: \(RodiLogger.masked(code))")
            #endif
            appleContinuation?.resume(returning: .success(code))
            appleContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            appleContinuation?.resume(returning: .failure(error))
            appleContinuation = nil
        }
    }
}

extension SocialLoginService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}

enum SocialLoginError: LocalizedError {
    case invalidAppleCredential
    case invalidAppleAuthorizationCode
    case kakaoSDKUnavailable
    case emptyKakaoToken

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            "Apple 로그인 정보를 확인하지 못했어요."
        case .invalidAppleAuthorizationCode:
            "Apple 인증 코드를 확인하지 못했어요."
        case .kakaoSDKUnavailable:
            "카카오 로그인 SDK가 연결되어 있지 않아요."
        case .emptyKakaoToken:
            "카카오 로그인 토큰을 확인하지 못했어요."
        }
    }
}
