import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@Suite(.serialized)
struct KoreanLocalizationRegressionTests {
    private static let highRiskKeys: [String] = [
        "Usage Dashboard",
        "Status Page",
        "Settings...",
        "About CodexBar",
        "Quit",
        "display_mode_title",
        "show_all_token_accounts_title",
        "show_all_token_accounts_subtitle",
        "multi_account_layout_stacked",
        "overview_tab_providers_title",
        "%@ left",
        "Resets %@",
        "Resets in %@",
        "Resets now",
        "Lasts until reset",
        "Projected empty in %@",
        "Runs out in %@",
        "Pace: %@",
        "%d%% in deficit",
        "%d%% in reserve",
        "usage_percent_suffix_left",
        "usage_percent_suffix_used",
        "Duration value minutes format",
        "Duration value hours format",
        "Duration value hours minutes format",
        "Duration value days format",
        "Duration value days hours format",
        "Duration future format",
        "Last 30 days",
        "Last 30 days:",
        "Last 30 days: %@ · %@ tokens",
        "Last 30 days: %@",
        "Last 30 days: %@ tokens",
        "Est. total (30d): %@",
        "Est. total (%@): %@",
        "cost_estimate_hint",
        "claude_cost_estimate_hint",
        "Estimated from local Codex logs for the selected account.",
        "Usage breakdown",
        "Usage breakdown chart",
        "No usage breakdown data.",
        "No usage breakdown data available.",
    ]

    private static let forbiddenEnglishFragments: [String] = [
        "Usage Dashboard",
        "Status Page",
        "Settings",
        "About CodexBar",
        "Quit",
        "Resets",
        "Runs out",
        "Projected empty",
        "Lasts until",
        "Pace:",
        "in deficit",
        "in reserve",
        "used",
        "left",
        "Last 30 days",
        "Est. total",
        "Estimated from local",
        "Usage breakdown",
        "No usage breakdown",
        "Display mode",
    ]

    @Test
    func `previously reported Korean UI strings do not fall back to English`() {
        for key in Self.highRiskKeys {
            let localized = L10n.string(key, localeIdentifier: "ko")
            #expect(localized != key, "Korean localization is missing for key: \(key)")
        }
    }

    @Test
    func `previously reported Korean UI strings do not retain English fragments`() {
        let samples = [
            L10n.string("Usage Dashboard", localeIdentifier: "ko"),
            L10n.string("Status Page", localeIdentifier: "ko"),
            L10n.string("Settings...", localeIdentifier: "ko"),
            L10n.string("About CodexBar", localeIdentifier: "ko"),
            L10n.string("Quit", localeIdentifier: "ko"),
            L10n.string("Resets %@", "1시간", localeIdentifier: "ko"),
            L10n.string("Runs out in %@", "4일 19시간", localeIdentifier: "ko"),
            L10n.string("Projected empty in %@", "45분", localeIdentifier: "ko"),
            L10n.string("%d%% in reserve", 0, localeIdentifier: "ko"),
            L10n.string("%d%% in deficit", 0, localeIdentifier: "ko"),
            L10n.string("usage_percent_suffix_used", localeIdentifier: "ko"),
            L10n.string("usage_percent_suffix_left", localeIdentifier: "ko"),
            L10n.string("Last 30 days", localeIdentifier: "ko"),
            L10n.string("Est. total (%@): %@", "최근 30일", "$9.00", localeIdentifier: "ko"),
            L10n.string("claude_cost_estimate_hint", localeIdentifier: "ko"),
            L10n.string("Usage breakdown", localeIdentifier: "ko"),
            L10n.string("No usage breakdown data.", localeIdentifier: "ko"),
        ]

        for sample in samples {
            for fragment in Self.forbiddenEnglishFragments {
                #expect(
                    !sample.localizedCaseInsensitiveContains(fragment),
                    "Korean sample contains English fragment '\(fragment)': \(sample)")
            }
        }
    }

    @Test
    func `runtime Korean formatting paths compose localized values`() {
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.korean.rawValue) {
            resetCodexBarLocalizationCacheForTesting()
            configureUsageFormatterLocalizationProvider()
            defer {
                UsageFormatter.clearLocalizationProvider()
                UsageFormatter.clearLocaleProvider()
                resetCodexBarLocalizationCacheForTesting()
            }

            #expect(LocalizedDurationText.valueDescription(minutes: 4 * 24 * 60 + 19 * 60) == "4일 19시간")
            #expect(LocalizedDurationText.futureDescription(minutes: 4 * 24 * 60 + 19 * 60) == "4일 19시간 후")
            #expect(
                UsageFormatter.costEstimateHint(provider: .claude)
                    == "로컬 Claude 로그를 API 요금으로 추정합니다. 토큰 합계에는 캐시 읽기/쓰기 토큰이 포함되며 Claude Code /status와 다를 수 있습니다.")
        }
    }
}
