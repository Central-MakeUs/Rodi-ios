import ActivityKit
import Foundation

/// 기존 Dev 앱의 운영 서버 세션을 인증·측정 복원 전에 한 번 정리합니다.
@MainActor
struct DevelopmentServerMigration {
    static let completionKey = "rodi.backend-migration.dev-api.v1.completed"

    static func runIfNeeded(
        configuration: AppBackendConfiguration,
        preferences: UserDefaults = .standard,
        legacyTokenStore: TokenStoring,
        tokenStore: TokenStoring,
        clearServerState: () -> Void
    ) {
        guard configuration.environment == .development,
              !preferences.bool(forKey: completionKey) else { return }

        legacyTokenStore.clear()
        tokenStore.clear()
        clearServerState()
        // 정리 요청을 모두 전달한 뒤 기록하여 중단된 초기화는 재시도합니다.
        preferences.set(true, forKey: completionKey)
    }

    static func clearServerState(userDefaults: UserDefaults = .standard) {
        // singleton이 저장된 측정을 복원하기 전에 저장소부터 비웁니다.
        DrivePracticeSessionStore(userDefaults: userDefaults).clear()
        PracticeMeasurementStore(userDefaults: userDefaults).clear()
        OnboardingProgressStore(
            preferencesStore: AppPreferencesStore(userDefaults: userDefaults),
            draftStore: OnboardingDraftStore(userDefaults: userDefaults)
        ).reset()
        RecentLoginProviderStore(userDefaults: userDefaults).clear()
        LevelUpPresentationStore.clearAll(userDefaults: userDefaults)

        if #available(iOS 16.1, *) {
            for activity in Activity<PracticeLiveActivityAttributes>.activities {
                PracticeLiveActivityService.shared.cancel(sessionID: activity.attributes.sessionID)
            }
        }
    }
}
