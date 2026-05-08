import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
@Suite(.serialized)
struct StatusMenuRefreshPreferenceTests {
    private func makeStatusBarForTesting() -> NSStatusBar {
        .system
    }

    private func makeSettings() -> SettingsStore {
        let suite = "StatusMenuRefreshPreferenceTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let configStore = testConfigStore(suiteName: suite)
        return SettingsStore(
            userDefaults: defaults,
            configStore: configStore,
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    @Test
    func `menu open refresh is gated by preference`() {
        StatusItemController.menuCardRenderingEnabled = false
        StatusItemController.setMenuRefreshEnabledForTesting(true)
        defer { StatusItemController.resetMenuRefreshEnabledForTesting() }

        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual
        settings.mergeIcons = false
        settings.menuOpenRefreshEnabled = false
        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)

        withStatusItemControllerForTesting(
            store: store,
            settings: settings,
            fetcher: fetcher,
            statusBar: self.makeStatusBarForTesting())
        { controller in
            var immediateRefreshCount = 0
            controller.onImmediateMenuRefreshAttemptForTesting = {
                immediateRefreshCount += 1
            }
            let menu = controller.makeMenu()

            controller.menuWillOpen(menu)
            #expect(immediateRefreshCount == 0)

            settings.menuOpenRefreshEnabled = true
            controller.menuWillOpen(menu)
            #expect(immediateRefreshCount == 1)
        }
    }

    @Test
    func `delayed menu refresh is gated by preference`() async {
        StatusItemController.menuCardRenderingEnabled = false
        StatusItemController.setMenuRefreshEnabledForTesting(true)
        StatusItemController.setMenuOpenRefreshDelayForTesting(.milliseconds(50))
        defer {
            StatusItemController.resetMenuOpenRefreshDelayForTesting()
            StatusItemController.resetMenuRefreshEnabledForTesting()
        }

        let settings = self.makeSettings()
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual
        settings.mergeIcons = false
        settings.menuOpenRefreshEnabled = false
        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        var delayedRefreshWakeCount = 0

        await withStatusItemControllerForTesting(
            store: store,
            settings: settings,
            fetcher: fetcher,
            statusBar: self.makeStatusBarForTesting())
        { controller in
            controller.onDelayedMenuRefreshAttemptForTesting = {
                delayedRefreshWakeCount += 1
            }
            controller.menuWillOpen(controller.makeMenu())
            try? await Task.sleep(for: .milliseconds(180))
        }

        #expect(delayedRefreshWakeCount == 0)
    }
}
