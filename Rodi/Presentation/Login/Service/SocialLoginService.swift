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

#if canImport(KakaoSDKCommon)
import KakaoSDKCommon
#endif

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

@MainActor
final class SocialLoginService: NSObject {
    private var appleContinuation: CheckedContinuation<Result<String, Error>, Never>?
    private var kakaoContinuation: CheckedContinuation<Result<String, Error>, Never>?
    private var kakaoLoginTimeoutTask: Task<Void, Never>?

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

    /// 카카오톡 앱 로그인에만 복구 가능한 오류가 발생한 경우 카카오계정 로그인으로 한 번 전환한다.
    func loginWithKakao() async -> Result<String, Error> {
        guard isKakaoTalkLoginAvailable else {
            return await loginWithKakaoAccount()
        }

        let result = await loginWithKakaoTalk()
        guard case .failure(let error) = result,
              error.shouldFallbackToKakaoAccountLogin
        else {
            return result
        }

        return await loginWithKakaoAccount()
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
            guard kakaoContinuation == nil else {
                continuation.resume(returning: .failure(SocialLoginError.kakaoLoginAlreadyInProgress))
                return
            }

            kakaoContinuation = continuation
            startKakaoLoginTimeout()

            let completion: (OAuthToken?, Error?) -> Void = { token, error in
                if let error {
                    Task { @MainActor [weak self] in
                        self?.finishKakaoLogin(with: .failure(error))
                    }
                } else if let accessToken = token?.accessToken, !accessToken.isEmpty {
                    Task { @MainActor [weak self] in
                        self?.finishKakaoLogin(with: .success(accessToken))
                    }
                } else {
                    Task { @MainActor [weak self] in
                        self?.finishKakaoLogin(with: .failure(SocialLoginError.emptyKakaoToken))
                    }
                }
            }

            request(completion)
        }
        #else
        .failure(SocialLoginError.kakaoSDKUnavailable)
        #endif
    }

    private func startKakaoLoginTimeout() {
        kakaoLoginTimeoutTask?.cancel()
        kakaoLoginTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(20))
            guard !Task.isCancelled else { return }
            self?.finishKakaoLogin(with: .failure(SocialLoginError.kakaoLoginTimedOut))
        }
    }

    private func finishKakaoLogin(with result: Result<String, Error>) {
        guard let continuation = kakaoContinuation else { return }

        kakaoContinuation = nil
        kakaoLoginTimeoutTask?.cancel()
        kakaoLoginTimeoutTask = nil
        continuation.resume(returning: result)
    }

    static func handleOpenURL(_ url: URL) -> Bool {
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
            appleContinuation?.resume(returning: .success(code))
            appleContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            let result: Result<String, Error>
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                result = .failure(SocialLoginError.appleAuthorizationCancelled)
            } else {
                result = .failure(error)
            }
            appleContinuation?.resume(returning: result)
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
    case appleAuthorizationCancelled
    case invalidAppleCredential
    case invalidAppleAuthorizationCode
    case kakaoSDKUnavailable
    case emptyKakaoToken
    case kakaoLoginCancelled
    case kakaoLoginTimedOut
    case kakaoLoginAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .appleAuthorizationCancelled:
            "Apple 로그인을 취소했어요."
        case .invalidAppleCredential:
            "Apple 로그인 정보를 확인하지 못했어요."
        case .invalidAppleAuthorizationCode:
            "Apple 인증 코드를 확인하지 못했어요."
        case .kakaoSDKUnavailable:
            "카카오 로그인 SDK가 연결되어 있지 않아요."
        case .emptyKakaoToken:
            "카카오 로그인 토큰을 확인하지 못했어요."
        case .kakaoLoginCancelled:
            "카카오 로그인을 취소했어요."
        case .kakaoLoginTimedOut:
            "카카오 로그인 시간이 초과되었어요. 다시 시도해 주세요."
        case .kakaoLoginAlreadyInProgress:
            "카카오 로그인이 이미 진행 중이에요."
        }
    }
}

extension Error {
    var isSocialLoginCancelled: Bool {
        if let error = self as? SocialLoginError,
           case .appleAuthorizationCancelled = error {
            return true
        }

        if let error = self as? SocialLoginError,
           case .kakaoLoginCancelled = error {
            return true
        }

        #if canImport(KakaoSDKCommon)
        guard let error = self as? SdkError else { return false }

        switch error {
        case .ClientFailed(reason: .Cancelled, errorMessage: _),
             .AuthFailed(reason: .AccessDenied, errorInfo: _):
            return true
        default:
            return false
        }
        #else
        return false
        #endif
    }

    /// 카카오톡 앱을 통한 인증을 계속할 수 없지만, 웹 카카오계정 인증으로는 복구 가능한 경우다.
    var shouldFallbackToKakaoAccountLogin: Bool {
        guard !isSocialLoginCancelled else { return false }

        #if canImport(KakaoSDKCommon)
        guard let error = self as? SdkError else { return false }

        switch error {
        case .ClientFailed(reason: .NotSupported, errorMessage: _),
             .ClientFailed(reason: .TokenNotFound, errorMessage: _),
             .AuthFailed(reason: .LoginRequired, errorInfo: _),
             .AuthFailed(reason: .ConsentRequired, errorInfo: _),
             .AuthFailed(reason: .InteractionRequired, errorInfo: _):
            return true
        default:
            return false
        }
        #else
        return false
        #endif
    }

    var kakaoLoginFailureMessage: String {
        if let error = self as? SocialLoginError {
            return error.localizedDescription
        }

        if let error = self as? NetworkError {
            switch error {
            case .networkUnavailable:
                return "네트워크 연결을 확인해 주세요."
            case .timeOut:
                return "카카오 로그인 요청 시간이 초과되었어요. 다시 시도해 주세요."
            case .apiError(_, let message, _):
                return message
            default:
                return "카카오 로그인에 실패했어요. 다시 시도해 주세요."
            }
        }

        let error = self as NSError
        if error.domain == NSURLErrorDomain,
           [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost
           ].contains(error.code) {
            return "네트워크 연결을 확인해 주세요."
        }

        #if canImport(KakaoSDKCommon)
        if let error = self as? SdkError {
            switch error {
            case .ClientFailed(reason: .MustInitAppKey, errorMessage: _),
                 .ClientFailed(reason: .BadParameter, errorMessage: _),
                 .ClientFailed(reason: .IllegalState, errorMessage: _),
                 .AuthFailed(reason: .InvalidRequest, errorInfo: _),
                 .AuthFailed(reason: .InvalidClient, errorInfo: _),
                 .AuthFailed(reason: .InvalidScope, errorInfo: _),
                 .AuthFailed(reason: .Misconfigured, errorInfo: _),
                 .AuthFailed(reason: .Unauthorized, errorInfo: _),
                 .AuthFailed(reason: .UnauthorizedClient, errorInfo: _):
                return "카카오 로그인 설정을 확인해 주세요."
            case .ClientFailed(reason: .Unknown, errorMessage: _),
                 .ClientFailed(reason: .TokenNotFound, errorMessage: _),
                 .AuthFailed(reason: .Unknown, errorInfo: _),
                 .AuthFailed(reason: .ServerError, errorInfo: _):
                return "카카오 로그인에 일시적인 문제가 있어요. 잠시 후 다시 시도해 주세요."
            default:
                break
            }
        }
        #endif

        return "카카오 로그인에 실패했어요. 다시 시도해 주세요."
    }
}
