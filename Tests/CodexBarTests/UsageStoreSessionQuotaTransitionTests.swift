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

    private func makeSettings(suiteName: String) throws -> SettingsStore {
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suiteName),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    @Test
    func `copilot switch from primary to secondary resets baseline`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-primary-secondary")
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
    func `copilot switch from secondary to primary resets baseline`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-secondary-primary")
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
    func `hundred percent threshold covers five hour session depletion`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-depleted-threshold")
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
    func `usage threshold notification fires after prior sample lands exactly on threshold`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-exact-threshold")
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = false
        settings.sessionQuotaUsageThresholds = [50]

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 50, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        settings.sessionQuotaThresholdNotificationsEnabled = true
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 51, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [.usageThreshold(50)])
    }

    @Test
    func `usage threshold notification posts only highest crossed threshold per refresh`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-highest-crossed")
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = true
        settings.sessionQuotaUsageThresholds = [50, 75]

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 45, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))
        store.handleSessionQuotaTransition(
            provider: .claude,
            snapshot: UsageSnapshot(
                primary: RateWindow(usedPercent: 80, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()))

        #expect(notifier.posts.map(\.transition) == [.usageThreshold(75)])
    }

    @Test
    func `depleted transition does not post separately when threshold alerts are disabled`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-depleted-disabled")
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
    func `usage threshold notification fires once per session window and resets after restore`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-threshold-reset")
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaThresholdNotificationsEnabled = true
        settings.sessionQuotaNotificationsEnabled = true
        settings.sessionQuotaUsageThresholds = [80]

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
    func `weekly threshold notification is independent from five hour threshold setting`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-threshold")
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
    func `weekly recovery notification fires when depleted weekly limit becomes available`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-recovery")
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
    func `weekly recovery notification respects disabled setting`() throws {
        let settings = try self.makeSettings(
            suiteName: "UsageStoreSessionQuotaTransitionTests-weekly-recovery-disabled")
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

    @Test
    func `claude weekly primary fallback does not emit session quota notifications`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-claude-weekly")
        settings.refreshFrequency = .manual
        settings.statusChecksEnabled = false
        settings.sessionQuotaNotificationsEnabled = true

        let notifier = SessionQuotaNotifierSpy()
        let store = UsageStore(
            fetcher: UsageFetcher(),
            browserDetection: BrowserDetection(cacheTTL: 0),
            settings: settings,
            sessionQuotaNotifier: notifier)

        let baseline = UsageSnapshot(
            primary: RateWindow(usedPercent: 20, windowMinutes: 7 * 24 * 60, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .claude, snapshot: baseline)

        let depleted = UsageSnapshot(
            primary: RateWindow(usedPercent: 100, windowMinutes: 7 * 24 * 60, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .claude, snapshot: depleted)

        #expect(notifier.posts.isEmpty)
    }

    @Test
    func `claude five hour primary still emits session quota notifications`() throws {
        let settings = try self.makeSettings(suiteName: "UsageStoreSessionQuotaTransitionTests-claude-session")
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

        let baseline = UsageSnapshot(
            primary: RateWindow(usedPercent: 20, windowMinutes: 5 * 60, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .claude, snapshot: baseline)

        let depleted = UsageSnapshot(
            primary: RateWindow(usedPercent: 100, windowMinutes: 5 * 60, resetsAt: nil, resetDescription: nil),
            secondary: nil,
            updatedAt: Date())
        store.handleSessionQuotaTransition(provider: .claude, snapshot: depleted)

        #expect(notifier.posts.map(\.transition) == [.usageThreshold(100)])
    }
}
