import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct LocalizationTests {
    @Test
    func `korean localization resolves core menu strings`() {
        #expect(L10n.string("menu.refresh", localeIdentifier: "ko") == "새로 고침")
        #expect(L10n.string("menu.settings", localeIdentifier: "ko") == "설정...")
        #expect(L10n.string("menu.quit", localeIdentifier: "ko") == "종료")
    }

    @Test
    func `korean localization resolves provider settings strings`() {
        #expect(L10n.string("Settings", localeIdentifier: "ko") == "설정")
        #expect(L10n.string("Cookie source", localeIdentifier: "ko") == "쿠키 소스")
        #expect(L10n.string("Automatic imports browser cookies.", localeIdentifier: "ko") == "브라우저 쿠키를 자동으로 가져옵니다.")
        #expect(L10n.string("Disabled", localeIdentifier: "ko") == "꺼짐")
    }

    @Test
    func `korean localization falls back to development language for missing keys`() {
        #expect(L10n.string("CodexBar", localeIdentifier: "ko") == "CodexBar")
    }

    @Test
    func `app language setting persists selected locale`() throws {
        let suite = "LocalizationTests-app-language-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = Self.makeSettingsStore(userDefaults: defaults, suiteName: suite)
        #expect(store.appLanguage == .system)

        store.appLanguage = .korean
        #expect(defaults.string(forKey: AppLanguage.userDefaultsKey) == AppLanguage.korean.rawValue)

        let restored = Self.makeSettingsStore(userDefaults: defaults, suiteName: suite, resetConfig: false)
        #expect(restored.appLanguage == .korean)
    }

    @Test
    func `korean localization resolves usage formatter strings`() {
        #expect(L10n.string("Updated just now", localeIdentifier: "ko") == "방금 업데이트됨")
        #expect(L10n.string("Percent left format", 42.0, localeIdentifier: "ko") == "42% 남음")
        #expect(L10n.string("Duration in hours format", 1, localeIdentifier: "ko") == "1시간 후")
        #expect(L10n.string("resetTimeDisplay.countdown", localeIdentifier: "ko") == "카운트다운 표시")
        #expect(L10n.string("resetTimeDisplay.absolute", localeIdentifier: "ko") == "초기화 시각 표시")
        #expect(L10n.string("resetTimeDisplay.both", localeIdentifier: "ko") == "둘 다 표시")
        #expect(L10n.string("Reset combined format", "1시간 후", "오후 3:00", localeIdentifier: "ko") == "1시간 후(오후 3:00)")
        #expect(L10n.string("metric.Session", localeIdentifier: "ko") == "세션")
        #expect(L10n.string("metric.Weekly", localeIdentifier: "ko") == "주간")
        #expect(L10n.string("Claude peak ends format", "6시간 후", localeIdentifier: "ko") == "피크 · 6시간 후 종료")
        #expect(L10n.string("option.Manual", localeIdentifier: "ko") == "수동")
        #expect(L10n.string("Never prompt", localeIdentifier: "ko") == "요청 안 함")
    }

    private static func makeSettingsStore(
        userDefaults: UserDefaults,
        suiteName: String,
        resetConfig: Bool = true) -> SettingsStore
    {
        SettingsStore(
            userDefaults: userDefaults,
            configStore: testConfigStore(suiteName: suiteName, reset: resetConfig),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore(),
            codexCookieStore: InMemoryCookieHeaderStore(),
            claudeCookieStore: InMemoryCookieHeaderStore(),
            cursorCookieStore: InMemoryCookieHeaderStore(),
            opencodeCookieStore: InMemoryCookieHeaderStore(),
            factoryCookieStore: InMemoryCookieHeaderStore(),
            minimaxCookieStore: InMemoryMiniMaxCookieStore(),
            minimaxAPITokenStore: InMemoryMiniMaxAPITokenStore(),
            kimiTokenStore: InMemoryKimiTokenStore(),
            kimiK2TokenStore: InMemoryKimiK2TokenStore(),
            augmentCookieStore: InMemoryCookieHeaderStore(),
            ampCookieStore: InMemoryCookieHeaderStore(),
            copilotTokenStore: InMemoryCopilotTokenStore(),
            tokenAccountStore: InMemoryTokenAccountStore())
    }
}
