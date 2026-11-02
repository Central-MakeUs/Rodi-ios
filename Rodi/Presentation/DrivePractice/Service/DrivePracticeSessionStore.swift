//
//  DrivePracticeSessionStore.swift
//  Rodi
//

import Foundation

/// DrivePracticeSession의 UserDefaults 저장·복구만 담당한다.
/// 기존 저장 키를 유지해 앱 재시작 뒤 진행 중인 측정을 복원할 수 있게 한다.
struct DrivePracticeSessionStore {
    private enum Key {
        static let activeSession = "rodi.practiceTracking.activeSession"
    }

    private let persistence: UserDefaultsCodableStore<DrivePracticeSession>

    init(userDefaults: UserDefaults = .standard) {
        persistence = UserDefaultsCodableStore(key: Key.activeSession, userDefaults: userDefaults)
    }

    func load() -> DrivePracticeSession? {
        do {
            return try persistence.decode()
        } catch {
            RodiLogger.warning("Practice tracking session restore failed")
            clear()
            return nil
        }
    }

    func save(_ session: DrivePracticeSession) {
        persistence.save(session)
    }

    func clear() {
        persistence.remove()
    }
}
