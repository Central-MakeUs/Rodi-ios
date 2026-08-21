//
//  KakaoLoginAdapter.swift
//  Rodi
//

import Foundation

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

#if canImport(KakaoSDKAuth)
import KakaoSDKAuth
#endif

#if canImport(KakaoSDKCommon)
import KakaoSDKCommon
#endif

@MainActor
final class KakaoLoginAdapter {
    private var continuation: CheckedContinuation<Result<String, Error>, Never>?
    private var timeoutTask: Task<Void, Never>?

    var isKakaoTalkLoginAvailable: Bool {
        #if canImport(KakaoSDKUser)
        UserApi.isKakaoTalkLoginAvailable()
        #else
        false
        #endif
    }

    func loginWithKakaoTalk() async -> Result<String, Error> {
        await login { completion in
            UserApi.shared.loginWithKakaoTalk(completion: completion)
        }
    }

    func loginWithKakaoAccount() async -> Result<String, Error> {
        await login { completion in
            UserApi.shared.loginWithKakaoAccount(completion: completion)
        }
    }

    private func login(
        request: @escaping (@escaping (OAuthToken?, Error?) -> Void) -> Void
    ) async -> Result<String, Error> {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            guard self.continuation == nil else {
                continuation.resume(returning: .failure(SocialLoginError.kakaoLoginAlreadyInProgress))
                return
            }

            self.continuation = continuation
            startTimeout()
            request { [weak self] token, error in
                Task { @MainActor in
                    if let error {
                        self?.finish(with: .failure(error))
                    } else if let accessToken = token?.accessToken, !accessToken.isEmpty {
                        self?.finish(with: .success(accessToken))
                    } else {
                        self?.finish(with: .failure(SocialLoginError.emptyKakaoToken))
                    }
                }
            }
        }
        #else
        .failure(SocialLoginError.kakaoSDKUnavailable)
        #endif
    }

    private func startTimeout() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled else { return }
            self?.finish(with: .failure(SocialLoginError.kakaoLoginTimedOut))
        }
    }

    private func finish(with result: Result<String, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        continuation.resume(returning: result)
    }
}
