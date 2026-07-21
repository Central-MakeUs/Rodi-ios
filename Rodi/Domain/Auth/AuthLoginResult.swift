//
//  AuthLoginResult.swift
//  Rodi
//

import Foundation

/// 소셜 로그인 시 인증 완료와 탈퇴 유예 상태를 구분합니다.
enum AuthLoginResult: Equatable {
    case authenticated(AuthToken)
    case withdrawalPending(AuthWithdrawalRecovery)
}

/// 탈퇴 유예 계정의 복구 및 재가입 안내에 필요한 서버 응답입니다.
struct AuthWithdrawalRecovery: Equatable {
    let provider: AuthProvider
    let withdrawalRequestedAt: Date?
    let recoverableUntil: Date?

    /// 탈퇴 요청일 기준 10일 뒤부터 재가입할 수 있습니다.
    var rejoinAvailableAt: Date? {
        guard let withdrawalRequestedAt else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return calendar.date(byAdding: .day, value: 10, to: withdrawalRequestedAt)
    }
}
