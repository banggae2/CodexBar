import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

@MainActor
struct UsageStoreSessionQuotaTransitionTests {
    @MainActor
    final class SessionQuotaNotifierSpy: SessionQuotaNotifying {
        private(set) var posts: [(transition: SessionQuotaTransition, provider: UsageProvider)] = []

        func post(transition: SessionQuotaTransition, provider: UsageProvider, badge _: NSNumber?) {
            self.posts.append((transition: transition, provider: provider))
        }
    }

    @Test
    func `copilot switch from primary to secondary resets baseline`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-primary-secondary"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaNotificationsEnabled = true

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        let primarySnapshot = UsageSnapshot(
            primary: RateWindow(usedPercent: 20, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .copilot, snapshot: primarySnapshot)

        let secondarySnapshot = UsageSnapshot(
            primary: nil,
            secondary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .copilot, snapshot: secondarySnapshot)

        #expect(notifier.posts.isEmpty)
    }

    @Test
    func `copilot switch from secondary to primary resets baseline`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-secondary-primary"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaNotificationsEnabled = true

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        let secondarySnapshot = UsageSnapshot(
            primary: nil,
            secondary: RateWindow(usedPercent: 20, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .copilot, snapshot: secondarySnapshot)

        let primarySnapshot = UsageSnapshot(
            primary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .copilot, snapshot: primarySnapshot)

        #expect(notifier.posts.isEmpty)
    }

    @Test
    func `hundred percent threshold covers five hour session depletion`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-depleted-threshold"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = true
        settings.sessionQuotaUsageThresholds = [100]

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 80, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [.usageThreshold(100)])
    }

    @Test
    func `depleted transition does not post separately when threshold alerts are disabled`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-depleted-disabled"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = false

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 80, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))

        #expect(notifier.posts.isEmpty)
    }

    @Test
    func `usage threshold notification fires once per session window and resets after restore`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-threshold-reset"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = true
        settings.sessionQuotaUsageThresholds = [80]
        settings.sessionQuotaNotificationsEnabled = true

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 70, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 85, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 90, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 20, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 85, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [
            .usageThreshold(80),
            .restored,
            .usageThreshold(80),
        ])
    }

    @Test
    func `weekly threshold notification is independent from five hour threshold setting`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-threshold"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = false
        settings.weeklyLimitThresholdNotificationsEnabled = true
        settings.weeklyLimitUsageThresholds = [50]

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 20, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 40, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 25, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 55, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [.weeklyUsageThreshold(50)])
    }

    @Test
    func `weekly recovery notification fires when depleted weekly limit becomes available`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-recovery"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = false
        settings.sessionQuotaNotificationsEnabled = false
        settings.weeklyLimitThresholdNotificationsEnabled = false
        settings.weeklyLimitRecoveryNotificationsEnabled = true

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 100, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 80, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 20, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [.weeklyRestored])
    }

    @Test
    func `weekly recovery notification respects disabled setting`() {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-recovery-disabled"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = false
        settings.sessionQuotaNotificationsEnabled = false
        settings.weeklyLimitThresholdNotificationsEnabled = false
        settings.weeklyLimitRecoveryNotificationsEnabled = false

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 100, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 80, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondary: RateWindow(usedPercent: 20, windowMinutes: 10080, resetsAt: nil, resetDescription: nil),
                updatedAt: Date()))

        #expect(notifier.posts.isEmpty)
    }
}
