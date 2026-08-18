import Foundation

/// `/auth/token/refresh` 응답은 신규 가입 여부를 주지 않는다.
/// 앱 시작 시 서버의 온보딩 완료 상태를 판정하는 데도 사용한다.
struct TokenRefreshResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
    let isOnboarded: Bool
    let isCourseTutorialCompleted: Bool
}
