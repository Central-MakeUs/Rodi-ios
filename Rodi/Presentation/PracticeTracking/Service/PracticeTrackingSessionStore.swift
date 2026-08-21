//
//  PracticeTrackingSessionStore.swift
//  Rodi
//

import Foundation

struct PracticeTrackingSessionStore {
    private enum Key {
        static let activeSession = "rodi.practiceTracking.activeSession"
    }

    private let persistence = UserDefaultsCodableStore<PracticeTrackingSession>(key: Key.activeSession)

    func load() -> PracticeTrackingSession? {
        do {
            return try persistence.decode()
        } catch {
            RodiLogger.warning("Practice tracking session restore failed")
            clear()
            return nil
        }
    }

    func save(_ session: PracticeTrackingSession) {
        persistence.save(session)
    }

    func clear() {
        persistence.remove()
    }
}
