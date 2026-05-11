import Foundation
import Testing
@testable import CodexBarCore

struct CodexCLIWindowNormalizationTests {
    @Test
    func `normalizer maps lone weekly window into secondary`() {
        let weekly = RateWindow(
            usedPercent: 5,
            windowMinutes: 10080,
            resetsAt: nil,
            resetDescription: nil)

        let normalized = CodexRateWindowNormalizer._normalizeForTesting(primary: weekly, secondary: nil)
        #expect(normalized.primary == nil)
        #expect(normalized.secondary?.usedPercent == 5)
        #expect(normalized.secondary?.windowMinutes == 10080)
    }

    @Test
    func `normalizer keeps lone session window in primary`() {
        let session = RateWindow(
            usedPercent: 31,
            windowMinutes: 300,
            resetsAt: nil,
            resetDescription: nil)

        let normalized = CodexRateWindowNormalizer._normalizeForTesting(primary: session, secondary: nil)
        #expect(normalized.primary?.usedPercent == 31)
        #expect(normalized.primary?.windowMinutes == 300)
        #expect(normalized.secondary == nil)
    }

    @Test
    func `normalizer keeps session and weekly ordering unchanged`() {
        let session = RateWindow(
            usedPercent: 31,
            windowMinutes: 300,
            resetsAt: nil,
            resetDescription: nil)
        let weekly = RateWindow(
            usedPercent: 26,
            windowMinutes: 10080,
            resetsAt: nil,
            resetDescription: nil)

        let normalized = CodexRateWindowNormalizer._normalizeForTesting(primary: session, secondary: weekly)
        #expect(normalized.primary?.usedPercent == 31)
        #expect(normalized.primary?.windowMinutes == 300)
        #expect(normalized.secondary?.usedPercent == 26)
        #expect(normalized.secondary?.windowMinutes == 10080)
    }

    @Test
    func `normalizer swaps reversed weekly and unknown windows`() {
        let weekly = RateWindow(
            usedPercent: 43,
            windowMinutes: 10080,
            resetsAt: nil,
            resetDescription: nil)
        let unknown = RateWindow(
            usedPercent: 17,
            windowMinutes: 540,
            resetsAt: nil,
            resetDescription: nil)

        let normalized = CodexRateWindowNormalizer._normalizeForTesting(primary: weekly, secondary: unknown)
        #expect(normalized.primary?.usedPercent == 17)
        #expect(normalized.primary?.windowMinutes == 540)
        #expect(normalized.secondary?.usedPercent == 43)
        #expect(normalized.secondary?.windowMinutes == 10080)
    }

    @Test
    func `maps weekly only RPC limits into secondary`() throws {
        let snapshot = try UsageFetcher._mapCodexRPCLimitsForTesting(
            primary: (usedPercent: 5, windowMinutes: 10080, resetsAt: nil),
            secondary: nil)

        #expect(snapshot.primary == nil)
        #expect(snapshot.secondary?.usedPercent == 5)
        #expect(snapshot.secondary?.windowMinutes == 10080)
    }

    @Test
    func `maps session only RPC limits into primary`() throws {
        let snapshot = try UsageFetcher._mapCodexRPCLimitsForTesting(
            primary: (usedPercent: 31, windowMinutes: 300, resetsAt: nil),
            secondary: nil)

        #expect(snapshot.primary?.usedPercent == 31)
        #expect(snapshot.primary?.windowMinutes == 300)
        #expect(snapshot.secondary == nil)
    }

    @Test
    func `maps reversed weekly and unknown RPC limits`() throws {
        let snapshot = try UsageFetcher._mapCodexRPCLimitsForTesting(
            primary: (usedPercent: 43, windowMinutes: 10080, resetsAt: nil),
            secondary: (usedPercent: 17, windowMinutes: 540, resetsAt: nil))

        #expect(snapshot.primary?.usedPercent == 17)
        #expect(snapshot.primary?.windowMinutes == 540)
        #expect(snapshot.secondary?.usedPercent == 43)
        #expect(snapshot.secondary?.windowMinutes == 10080)
    }

    @Test
    func `maps named RPC limit buckets into extra rate windows`() throws {
        let json = """
        {
          "rateLimits": {
            "limitId": "codex",
            "primary": { "usedPercent": 34, "windowDurationMins": 300, "resetsAt": 1778501492 },
            "secondary": { "usedPercent": 59, "windowDurationMins": 10080, "resetsAt": 1778590095 },
            "credits": { "hasCredits": false, "unlimited": false, "balance": "0" },
            "planType": "prolite",
            "rateLimitReachedType": null
          },
          "rateLimitsByLimitId": {
            "codex": {
              "limitId": "codex",
              "primary": { "usedPercent": 34, "windowDurationMins": 300, "resetsAt": 1778501492 },
              "secondary": { "usedPercent": 59, "windowDurationMins": 10080, "resetsAt": 1778590095 }
            },
            "codex_bengalfox": {
              "limitId": "codex_bengalfox",
              "limitName": "GPT-5.3-Codex-Spark",
              "primary": { "usedPercent": 100, "windowDurationMins": 300, "resetsAt": 1778502228 },
              "secondary": { "usedPercent": 30, "windowDurationMins": 10080, "resetsAt": 1779089028 }
            }
          }
        }
        """

        let snapshot = try UsageFetcher._mapCodexRPCLimitsResponseForTesting(Data(json.utf8))

        #expect(snapshot.primary?.usedPercent == 34)
        #expect(snapshot.secondary?.usedPercent == 59)
        #expect(snapshot.extraRateWindows?.map(\.title) == [
            "GPT-5.3-Codex-Spark 5h",
            "GPT-5.3-Codex-Spark weekly",
        ])
        #expect(snapshot.extraRateWindows?.map(\.window.usedPercent) == [100, 30])
        #expect(snapshot.extraRateWindows?.map(\.window.windowMinutes) == [300, 10080])
    }

    @Test
    func `throws when RPC limits contain no windows`() {
        #expect(throws: UsageError.noRateLimitsFound) {
            try UsageFetcher._mapCodexRPCLimitsForTesting(primary: nil, secondary: nil)
        }
    }

    @Test
    func `maps weekly only status snapshot into secondary`() throws {
        let status = CodexStatusSnapshot(
            credits: nil,
            fiveHourPercentLeft: nil,
            weeklyPercentLeft: 95,
            fiveHourResetDescription: nil,
            weeklyResetDescription: "resets next week",
            fiveHourResetsAt: nil,
            weeklyResetsAt: nil,
            rawText: "Weekly limit: 95% left")

        let snapshot = try UsageFetcher._mapCodexStatusForTesting(status)
        #expect(snapshot.primary == nil)
        #expect(snapshot.secondary?.usedPercent == 5)
        #expect(snapshot.secondary?.windowMinutes == 10080)
    }

    @Test
    func `maps five hour only status snapshot into primary`() throws {
        let status = CodexStatusSnapshot(
            credits: nil,
            fiveHourPercentLeft: 69,
            weeklyPercentLeft: nil,
            fiveHourResetDescription: "resets soon",
            weeklyResetDescription: nil,
            fiveHourResetsAt: nil,
            weeklyResetsAt: nil,
            rawText: "5h limit: 69% left")

        let snapshot = try UsageFetcher._mapCodexStatusForTesting(status)
        #expect(snapshot.primary?.usedPercent == 31)
        #expect(snapshot.primary?.windowMinutes == 300)
        #expect(snapshot.secondary == nil)
    }

    @Test
    func `throws when status snapshot contains no windows`() {
        let status = CodexStatusSnapshot(
            credits: nil,
            fiveHourPercentLeft: nil,
            weeklyPercentLeft: nil,
            fiveHourResetDescription: nil,
            weeklyResetDescription: nil,
            fiveHourResetsAt: nil,
            weeklyResetsAt: nil,
            rawText: "")

        #expect(throws: UsageError.noRateLimitsFound) {
            try UsageFetcher._mapCodexStatusForTesting(status)
        }
    }
}
