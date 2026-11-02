import XCTest
@testable import Rodi

@MainActor
final class BackendEnvironmentTests: XCTestCase {
    func testEnvironmentSelectsSeparateTokenNamespacesWithoutChangingProduction() throws {
        let dev = try configuration(.development)
        let prod = try configuration(.production)
        XCTAssertEqual(dev.tokenService, "com.dororong.rodi.dev.dev-api.stillstar.store")
        XCTAssertEqual(prod.tokenService, "com.dororong.rodi")
        XCTAssertNotEqual(dev.tokenService, prod.tokenService)
    }

    func testMixedEnvironmentOrServerIsRejected() {
        XCTAssertThrowsError(try AppBackendConfiguration(environment: "unknown", bundleIdentifier: "com.dororong.rodi.dev", baseURL: "https://dev-api.stillstar.store"))
        XCTAssertThrowsError(try AppBackendConfiguration(environment: "dev", bundleIdentifier: "com.dororong.rodi", baseURL: "https://dev-api.stillstar.store"))
        for url in ["", "https://api.stillstar.store", "http://dev-api.stillstar.store",
                    "https://dev-api.stillstar.store:443", "https://dev-api.stillstar.store/path",
                    "https://dev-api.stillstar.store?query=value", "https://user@dev-api.stillstar.store",
                    "https://dev-api.stillstar.store.evil.example"] {
            XCTAssertThrowsError(try AppBackendConfiguration(environment: "dev", bundleIdentifier: "com.dororong.rodi.dev", baseURL: url))
        }
    }

    func testInitialMigrationClearsBothTokenStoresBeforeRecordingCompletion() throws {
        let (defaults, suite) = makePreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = InMemoryTokenStore(accessToken: "old-test-token", refreshToken: "old-test-refresh")
        let current = InMemoryTokenStore(accessToken: "interrupted-test-token")
        var calls = 0

        DevelopmentServerMigration.runIfNeeded(
            configuration: try configuration(.development), preferences: defaults,
            legacyTokenStore: legacy, tokenStore: current
        ) {
            XCTAssertNil(legacy.accessToken)
            XCTAssertNil(legacy.refreshToken)
            XCTAssertNil(current.accessToken)
            XCTAssertFalse(defaults.bool(forKey: DevelopmentServerMigration.completionKey))
            calls += 1
        }
        XCTAssertEqual(calls, 1)
        XCTAssertTrue(defaults.bool(forKey: DevelopmentServerMigration.completionKey))
    }

    func testRelaunchPreservesNewDevelopmentSession() throws {
        let (defaults, suite) = makePreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = InMemoryTokenStore()
        let current = InMemoryTokenStore()
        let dev = try configuration(.development)
        var calls = 0
        DevelopmentServerMigration.runIfNeeded(configuration: dev, preferences: defaults, legacyTokenStore: legacy, tokenStore: current) { calls += 1 }
        current.update(accessToken: "new-test-token", refreshToken: "new-test-refresh")
        DevelopmentServerMigration.runIfNeeded(configuration: dev, preferences: defaults, legacyTokenStore: legacy, tokenStore: current) { calls += 1 }

        XCTAssertEqual(calls, 1)
        XCTAssertEqual(current.accessToken, "new-test-token")
        XCTAssertEqual(current.refreshToken, "new-test-refresh")
    }

    func testProductionNeverRunsDevelopmentCleanup() throws {
        let (defaults, suite) = makePreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = InMemoryTokenStore(accessToken: "prod-test-token")
        let current = InMemoryTokenStore(refreshToken: "prod-test-refresh")
        DevelopmentServerMigration.runIfNeeded(
            configuration: try configuration(.production), preferences: defaults,
            legacyTokenStore: legacy, tokenStore: current
        ) { XCTFail("Prod 저장 데이터는 정리하면 안 됩니다.") }
        XCTAssertEqual(legacy.accessToken, "prod-test-token")
        XCTAssertEqual(current.refreshToken, "prod-test-refresh")
        XCTAssertNil(defaults.object(forKey: DevelopmentServerMigration.completionKey))
    }

    func testLevelUpCleanupPreservesUnrelatedPreferences() {
        let (defaults, suite) = makePreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data([1]), forKey: "rodi.level-up-presentation.test-account")
        defaults.set("kept", forKey: "unrelated-search-history")
        LevelUpPresentationStore.clearAll(userDefaults: defaults)
        XCTAssertNil(defaults.object(forKey: "rodi.level-up-presentation.test-account"))
        XCTAssertEqual(defaults.string(forKey: "unrelated-search-history"), "kept")
    }

    func testLegacyServerStateIsRemovedWithoutErasingIndependentSettings() {
        let (defaults, suite) = makePreferences()
        defer { defaults.removePersistentDomain(forName: suite) }
        let serverKeys = [
            "rodi.practiceTracking.activeSession", "rodi.practice-measurement",
            "rodi.practice-return-prompt", "rodi.onboarding.draft",
            "rodi.auth.recent-login-provider", "rodi.level-up-presentation.test-account"
        ]
        serverKeys.forEach { defaults.set(Data([1]), forKey: $0) }
        AppPreferencesStore(userDefaults: defaults).markOnboardingSeen()
        defaults.set("kept-search", forKey: "unrelated-search-history")
        defaults.set("kept-navigation", forKey: "unrelated-navigation-preference")

        DevelopmentServerMigration.clearServerState(userDefaults: defaults)

        serverKeys.forEach { XCTAssertNil(defaults.object(forKey: $0)) }
        XCTAssertFalse(AppPreferencesStore(userDefaults: defaults).hasSeenOnboarding())
        XCTAssertEqual(defaults.string(forKey: "unrelated-search-history"), "kept-search")
        XCTAssertEqual(defaults.string(forKey: "unrelated-navigation-preference"), "kept-navigation")
    }

    private func configuration(_ environment: AppEnvironment) throws -> AppBackendConfiguration {
        try .init(
            environment: environment.rawValue,
            bundleIdentifier: environment.isProduction ? "com.dororong.rodi" : "com.dororong.rodi.dev",
            baseURL: environment.isProduction ? "https://api.stillstar.store" : "https://dev-api.stillstar.store"
        )
    }

    private func makePreferences() -> (UserDefaults, String) {
        let suite = "BackendEnvironmentTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }
}
