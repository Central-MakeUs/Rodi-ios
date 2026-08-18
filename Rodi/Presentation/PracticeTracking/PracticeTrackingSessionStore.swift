//
//  PracticeTrackingSessionStore.swift
//  Rodi
//

import Foundation

struct PracticeTrackingSessionStore {
    private enum Key {
        static let activeSession = "rodi.practiceTracking.activeSession"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> PracticeTrackingSession? {
        guard let data = userDefaults.data(forKey: Key.activeSession) else { return nil }

        do {
            return try JSONDecoder().decode(PracticeTrackingSession.self, from: data)
        } catch {
            RodiLogger.warning("Practice tracking session restore failed: \(error.localizedDescription)")
            clear()
            return nil
        }
    }

    func save(_ session: PracticeTrackingSession) {
        do {
            let data = try JSONEncoder().encode(session)
            userDefaults.set(data, forKey: Key.activeSession)
        } catch {
            RodiLogger.warning("Practice tracking session save failed: \(error.localizedDescription)")
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: Key.activeSession)
    }
}
