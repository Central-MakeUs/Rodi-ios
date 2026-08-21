//
//  AppleLoginAdapter.swift
//  Rodi
//

import AuthenticationServices
import UIKit

@MainActor
final class AppleLoginAdapter: NSObject {
    private var continuation: CheckedContinuation<Result<String, Error>, Never>?

    func login() async -> Result<String, Error> {
        await withCheckedContinuation { continuation in
            guard self.continuation == nil else {
                continuation.resume(returning: .failure(SocialLoginError.appleLoginAlreadyInProgress))
                return
            }

            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func finish(with result: Result<String, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: result)
    }
}

extension AppleLoginAdapter: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                finish(with: .failure(SocialLoginError.invalidAppleCredential))
                return
            }

            guard let authorizationCode = credential.authorizationCode,
                  let code = String(data: authorizationCode, encoding: .utf8),
                  !code.isEmpty else {
                finish(with: .failure(SocialLoginError.invalidAppleAuthorizationCode))
                return
            }

            RodiLogger.info("Apple sign-in succeeded userID=\(RodiLogger.masked(credential.user))")
            finish(with: .success(code))
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                finish(with: .failure(SocialLoginError.appleAuthorizationCancelled))
            } else {
                finish(with: .failure(error))
            }
        }
    }
}

extension AppleLoginAdapter: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            return scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
