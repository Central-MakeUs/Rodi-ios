//
//  OnboardingProgressStore.swift
//  Rodi
//

import Foundation

/// 온보딩 완료 여부와 미완료 초안의 저장 정책을 한곳에서 관리한다.
struct OnboardingProgressStore {
    private let preferencesStore: AppPreferencesStore
    private let draftStore: OnboardingDraftStore

    init(
        preferencesStore: AppPreferencesStore = AppPreferencesStore(),
        draftStore: OnboardingDraftStore = OnboardingDraftStore()
    ) {
        self.preferencesStore = preferencesStore
        self.draftStore = draftStore
    }

    var hasCompleted: Bool {
        preferencesStore.hasSeenOnboarding()
    }

    func markCompleted() {
        draftStore.clear()
        preferencesStore.markOnboardingSeen()
    }

    func reset() {
        draftStore.clear()
        preferencesStore.resetOnboardingSeen()
    }
}
