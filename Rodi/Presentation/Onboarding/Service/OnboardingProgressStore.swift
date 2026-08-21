//
//  OnboardingProgressStore.swift
//  Rodi
//

import Foundation

/// 온보딩 Feature의 완료 여부와 미완료 초안 정리 정책을 관리한다.
struct OnboardingProgressStore {
    private let preferencesStore: AppPreferencesStore
    private let draftStore: OnboardingDraftStore

    init(
        preferencesStore: AppPreferencesStore = .init(),
        draftStore: OnboardingDraftStore = .init()
    ) {
        self.preferencesStore = preferencesStore
        self.draftStore = draftStore
    }

    var hasCompleted: Bool {
        preferencesStore.hasSeenOnboarding()
    }

    var hasInProgressDraft: Bool {
        draftStore.load() != nil
    }

    func clearDraft() {
        draftStore.clear()
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
