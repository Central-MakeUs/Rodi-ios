//
//  OnboardingSessionStore.swift
//  Rodi
//

import Foundation

/// 온보딩 화면 상태와 Local 초안 payload 사이의 변환을 소유한다.
///
/// `Data/Local`은 payload 저장만 담당하고, 화면 route와 session 복원 정책은
/// Onboarding Feature 안에 남긴다.
struct OnboardingSessionStore {
    private let draftStore: OnboardingDraftStore
    private let progressStore: OnboardingProgressStore

    init(draftStore: OnboardingDraftStore = .init()) {
        self.draftStore = draftStore
        progressStore = OnboardingProgressStore(draftStore: draftStore)
    }

    func load() -> (session: OnboardingSession, route: OnboardingRoute?) {
        let payload = draftStore.load()
        return (
            OnboardingSession(payload: payload),
            OnboardingSession.initialRoute(payload: payload)
        )
    }

    func save(_ session: OnboardingSession, route: OnboardingRoute) {
        guard let payload = session.draftPayload(route: route) else { return }
        draftStore.save(payload)
    }

    func markCompleted() {
        progressStore.markCompleted()
    }
}
