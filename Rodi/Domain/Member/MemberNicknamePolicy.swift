import Foundation

/// 서버 저장 전 확인할 수 있는 닉네임 형식만 검사합니다.
nonisolated enum MemberNicknamePolicy {
    static let maximumLength = 10

    static func normalized(_ nickname: String) -> String {
        nickname.precomposedStringWithCanonicalMapping
    }

    static func isValid(_ nickname: String) -> Bool {
        let value = normalized(nickname)
        guard (2...maximumLength).contains(value.count) else { return false }
        return value.range(
            of: "\\A[가-힣A-Za-z0-9]+(?:_[가-힣A-Za-z0-9]+)*\\z",
            options: .regularExpression
        ) != nil
    }
}
