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
        let previousStandardLanguage = UserDefaults.standard.object(forKey: AppLanguage.userDefaultsKey)
        let previousAppleLanguages = UserDefaults.standard.object(forKey: "AppleLanguages")
        defer {
            if let previousStandardLanguage {
                UserDefaults.standard.set(previousStandardLanguage, forKey: AppLanguage.userDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppLanguage.userDefaultsKey)
            }
            if let previousAppleLanguages {
                UserDefaults.standard.set(previousAppleLanguages, forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }

        let suite = "LocalizationTests-app-language-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = Self.makeSettingsStore(userDefaults: defaults, suiteName: suite)
        #expect(store.appLanguage == AppLanguage.system.rawValue)

        store.appLanguage = AppLanguage.korean.rawValue
        #expect(defaults.string(forKey: AppLanguage.userDefaultsKey) == AppLanguage.korean.rawValue)

        let restored = Self.makeSettingsStore(userDefaults: defaults, suiteName: suite, resetConfig: false)
        #expect(restored.appLanguage == AppLanguage.korean.rawValue)
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

    @Test
    func `korean localization resolves visible usage pace and cost strings`() {
        #expect(L10n.string("Resets %@", "1시간", localeIdentifier: "ko") == "1시간 재설정")
        #expect(L10n.string("Runs out in %@", "4일 19시간", localeIdentifier: "ko") == "4일 19시간 후 소진 예상")
        #expect(L10n.string("%d%% in reserve", 0, localeIdentifier: "ko") == "0% 여유")
        #expect(L10n.string("%d%% in deficit", 0, localeIdentifier: "ko") == "0% 부족")
        #expect(L10n.string("usage_percent_suffix_used", localeIdentifier: "ko") == "사용됨")
        #expect(L10n.string("Last 30 days", localeIdentifier: "ko") == "최근 30일")
        #expect(L10n.string("Last 30 days: %@", "$9.00", localeIdentifier: "ko") == "최근 30일: $9.00")
        #expect(L10n.string("Est. total (%@): %@", "최근 30일", "$9.00", localeIdentifier: "ko") == "추정 합계(최근 30일): $9.00")

        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.korean.rawValue) {
            resetCodexBarLocalizationCacheForTesting()
            configureUsageFormatterLocalizationProvider()
            defer {
                UsageFormatter.clearLocalizationProvider()
                UsageFormatter.clearLocaleProvider()
                resetCodexBarLocalizationCacheForTesting()
            }

            #expect(UsageFormatter.costEstimateHint(provider: .claude) == "로컬 Claude 로그를 API 요금으로 추정합니다. 토큰 합계에는 캐시 읽기/쓰기 토큰이 포함되며 Claude Code /status와 다를 수 있습니다.")
        }
    }

    @Test
    func `korean localization resolves merged display settings strings`() {
        #expect(L10n.string("display_mode_title", localeIdentifier: "ko") == "표시 방식")
        #expect(L10n.string("show_all_token_accounts_title", localeIdentifier: "ko") == "모든 토큰 계정 표시")
        #expect(L10n.string("show_all_token_accounts_subtitle", localeIdentifier: "ko").contains("스택 방식"))
        #expect(L10n.string("multi_account_layout_stacked", localeIdentifier: "ko") == "스택")
        #expect(L10n.string("overview_tab_providers_title", localeIdentifier: "ko") == "개요 탭 공급자")
    }

    @Test
    func `korean localization covers visible upstream settings strings`() {
        #expect(L10n.string("tab_advanced", localeIdentifier: "ko") == "고급")
        #expect(L10n.string("section_notifications", localeIdentifier: "ko") == "알림")
        #expect(L10n.string("refresh_cadence_title", localeIdentifier: "ko") == "새로 고침 주기")
        #expect(L10n.string("open_menu_shortcut_title", localeIdentifier: "ko") == "메뉴 열기")
        #expect(L10n.string("show_debug_settings_title", localeIdentifier: "ko") == "디버그 설정 표시")
        #expect(L10n.string("quota_warning_notifications_title", localeIdentifier: "ko") == "할당량 경고 알림")
    }

    @Test
    func `multi account layout labels follow selected Korean language`() {
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.korean.rawValue) {
            #expect(MultiAccountMenuLayout.segmented.label == "전환 막대")
            #expect(MultiAccountMenuLayout.stacked.label == "스택")
        }
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
