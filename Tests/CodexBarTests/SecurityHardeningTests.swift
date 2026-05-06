import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct ProviderDetectionSecurityTests {
    @Test
    func `initial detection does not auto enable Gemini`() {
        let enablement = SettingsStore.providerDetectionEnablement(
            codexInstalled: false,
            claudeInstalled: false,
            geminiInstalled: true,
            antigravityRunning: false)

        #expect(enablement.codex == false)
        #expect(enablement.claude == false)
        #expect(enablement.gemini == false)
        #expect(enablement.antigravity == false)
    }
}

struct ProviderEndpointSafetyTests {
    @Test
    func `Zai rejects unsafe quota URL overrides`() {
        let url = ZaiSettingsReader.quotaURL(environment: [ZaiSettingsReader.quotaURLKey: "https://evil.example/quota"])

        #expect(url == nil)
    }

    @Test
    func `Alibaba rejects unsafe quota URL overrides`() {
        let url = AlibabaCodingPlanSettingsReader
            .quotaURL(environment: [AlibabaCodingPlanSettingsReader.quotaURLKey: "https://evil.example/quota"])

        #expect(url == nil)
    }

    @Test
    func `OpenRouter ignores unsafe API URL overrides`() {
        let url = OpenRouterSettingsReader.apiURL(environment: ["OPENROUTER_API_URL": "https://evil.example/api/v1"])

        #expect(url.absoluteString == "https://openrouter.ai/api/v1")
    }

    @Test
    func `MiniMax rejects unsafe URL overrides`() {
        let url = MiniMaxSettingsReader.remainsURL(
            environment: [MiniMaxSettingsReader.remainsURLKey: "https://evil.example/custom/remains"])

        #expect(url == nil)
    }
}

struct AugmentSessionKeepaliveSecurityTests {
    @Test
    func `cookie summaries do not include values`() {
        let summary = AugmentSessionKeepalive.safeCookieSummary("auth=secret-token; sid=session-id")

        #expect(summary.contains("auth"))
        #expect(summary.contains("sid"))
        #expect(!summary.contains("secret-token"))
        #expect(!summary.contains("session-id"))
    }
}
