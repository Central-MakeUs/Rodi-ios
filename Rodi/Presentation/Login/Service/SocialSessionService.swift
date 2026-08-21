import Foundation

#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

/// 소셜 SDK 세션 정리는 Login Feature가 소유한다.
@MainActor
final class SocialSessionService {
    func logoutKakaoSessionIfNeeded() async {
        #if canImport(KakaoSDKUser)
        await withCheckedContinuation { continuation in
            UserApi.shared.logout { error in
                if error != nil {
                    RodiLogger.warning("Kakao SDK logout failed or no active Kakao session")
                } else {
                    RodiLogger.info("Kakao SDK logout completed")
                }
                continuation.resume()
            }
        }
        #endif
    }
}
