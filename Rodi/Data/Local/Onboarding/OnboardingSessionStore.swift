//
//  OnboardingSessionStore.swift
//  Rodi
//

import Foundation

struct OnboardingSessionStore {
    private let draftStore: OnboardingDraftStore
    private let progressStore: OnboardingProgressStore

    init(draftStore: OnboardingDraftStore = .init()) {
        self.draftStore = draftStore
        progressStore = OnboardingProgressStore(draftStore: draftStore)
    }

    func load() -> (session: OnboardingSession, route: OnboardingRoute?) {
        let payload = draftStore.load()
        return (OnboardingSession(payload: payload), OnboardingSession.initialRoute(payload: payload))
    }

    func save(_ session: OnboardingSession, route: OnboardingRoute) {
        guard let payload = session.draftPayload(route: route) else { return }
        draftStore.save(payload)
    }

    func markCompleted() {
        progressStore.markCompleted()
    }
}
