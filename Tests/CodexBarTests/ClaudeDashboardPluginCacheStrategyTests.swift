import Foundation
import Testing
@testable import CodexBarCore

@Suite(.serialized)
struct ClaudeDashboardPluginCacheStrategyTests {
    private func makeContext() -> ProviderFetchContext {
        let browserDetection = BrowserDetection(cacheTTL: 0)
        return ProviderFetchContext(
            runtime: .app,
            sourceMode: .claudeDashboardPlugin,
            includeCredits: false,
            webTimeout: 1,
            webDebugDumpHTML: false,
            verbose: false,
            env: [:],
            settings: nil,
            fetcher: UsageFetcher(),
            claudeFetcher: ClaudeUsageFetcher(browserDetection: browserDetection),
            browserDetection: browserDetection)
    }

    @Test
    func `reads latest claude dashboard plugin cache as quota windows`() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("claude-dashboard-plugin-cache-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let older = tempDir.appendingPathComponent("cache-old.json")
        try Data("""
        {
          "data": {
            "five_hour": { "utilization": 99, "resets_at": "2026-05-07T10:40:00.000Z" }
          },
          "timestamp": 1778140000000
        }
        """.utf8).write(to: older)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1_778_140_000)],
            ofItemAtPath: older.path)

        let latest = tempDir.appendingPathComponent("cache-new.json")
        try Data("""
        {
          "data": {
            "five_hour": { "utilization": 10, "resets_at": "2026-05-07T11:40:00.291721+00:00" },
            "seven_day": { "utilization": 55, "resets_at": "2026-05-08T19:00:01.291746+00:00" },
            "seven_day_sonnet": { "utilization": 3, "resets_at": "2026-05-08T19:00:01.291756+00:00" }
          },
          "timestamp": 1778147843413
        }
        """.utf8).write(to: latest)
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSince1970: 1_778_147_843)],
            ofItemAtPath: latest.path)

        let strategy = ClaudeDashboardPluginCacheFetchStrategy(cacheDirectory: tempDir)
        let result = try await strategy.fetch(self.makeContext())

        #expect(result.strategyID == "claude.dashboard-plugin")
        #expect(result.sourceLabel == "claude-dashboard-plugin")
        #expect(result.usage.primary?.usedPercent == 10)
        #expect(result.usage.primary?.windowMinutes == 5 * 60)
        #expect(result.usage.secondary?.usedPercent == 55)
        #expect(result.usage.secondary?.windowMinutes == 7 * 24 * 60)
        #expect(result.usage.tertiary?.usedPercent == 3)
        #expect(result.usage.identity?.loginMethod == "Claude Dashboard Plugin")
    }

    @Test
    func `unavailable when claude dashboard plugin cache is absent`() async {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-claude-dashboard-plugin-cache-\(UUID().uuidString)", isDirectory: true)
        let strategy = ClaudeDashboardPluginCacheFetchStrategy(cacheDirectory: tempDir)

        #expect(await strategy.isAvailable(self.makeContext()) == false)
    }
}
