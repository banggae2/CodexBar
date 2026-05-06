import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@Suite(.serialized)
@MainActor
struct MenuBarCompactUsageRendererTests {
    private func entry(
        provider: UsageProvider = .codex,
        code: String = "cx",
        percent: Double? = 50,
        secondaryPercent: Double? = nil) -> MenuBarCompactUsageRenderer.Entry
    {
        MenuBarCompactUsageRenderer.Entry(
            provider: provider,
            code: code,
            percent: percent,
            secondaryPercent: secondaryPercent,
            color: ProviderColor(red: 0.3, green: 0.6, blue: 0.8))
    }

    private func makeStatusBarForTesting() -> NSStatusBar {
        let env = ProcessInfo.processInfo.environment
        if env["GITHUB_ACTIONS"] == "true" || env["CI"] == "true" {
            return .system
        }
        return NSStatusBar()
    }

    private func columnHasVisiblePixels(_ image: NSImage, x: Int) -> Bool {
        var rect = NSRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return false }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard x >= 0, x < rep.pixelsWide else { return false }
        for y in 0..<rep.pixelsHigh where (rep.colorAt(x: x, y: y) ?? .clear).alphaComponent > 0.01 {
            return true
        }
        return false
    }

    @Test
    func `compact usage display lays out two rows and uses selected percent direction`() {
        #expect(MenuBarCompactUsageRenderer.providerCode(for: .claude) == "cc")
        #expect(MenuBarCompactUsageRenderer.providerCode(for: .codex) == "cx")
        #expect(MenuBarCompactUsageRenderer.rowGroups([1, 2]).map(\.count) == [1, 1])
        #expect(MenuBarCompactUsageRenderer.rowGroups([1, 2, 3, 4, 5]).map(\.count) == [3, 2])
        #expect(MenuBarCompactUsageRenderer.segmentFillCount(percent: 41) == 2)

        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "MenuBarCompactUsageRendererTests-compact-usage"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual
        settings.mergeIcons = true
        settings.menuBarShowsBrandIconWithPercent = true
        settings.menuBarUsageDisplayStyle = .compactBars

        let registry = ProviderRegistry.shared
        if let codexMeta = registry.metadata[.codex] {
            settings.setProviderEnabled(provider: .codex, metadata: codexMeta, enabled: true)
        }
        if let claudeMeta = registry.metadata[.claude] {
            settings.setProviderEnabled(provider: .claude, metadata: claudeMeta, enabled: true)
        }

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())

        let codexSnapshot = UsageSnapshot(
            primary: RateWindow(usedPercent: 40, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            secondary: RateWindow(usedPercent: 47, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            updatedAt: Date())
        let claudeSnapshot = UsageSnapshot(
            primary: RateWindow(usedPercent: 75, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            secondary: RateWindow(usedPercent: 25, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            updatedAt: Date())
        store._setSnapshotForTesting(codexSnapshot, provider: .codex)
        store._setSnapshotForTesting(claudeSnapshot, provider: .claude)

        settings.usageBarsShowUsed = false
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map(\.percent) == [60, 25])
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map(\.secondaryPercent) == [53, 75])
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map {
            MenuBarCompactUsageRenderer.percentText(for: $0)
        } == ["60%/53%", "25%/75%"])

        settings.usageBarsShowUsed = true
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map(\.percent) == [40, 75])
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map(\.secondaryPercent) == [47, 25])
        #expect(controller.menuBarCompactUsageEntries(for: [.codex, .claude]).map {
            MenuBarCompactUsageRenderer.percentText(for: $0)
        } == ["40%/47%", "75%/25%"])
    }

    @Test
    func `compact usage display keeps single percentage when weekly window is missing`() {
        let entry = self.entry(percent: 60, secondaryPercent: nil)
        #expect(MenuBarCompactUsageRenderer.percentText(for: entry) == "60%")
    }

    @Test
    func `compact usage display expands for three digit percentages`() throws {
        let twoDigitImage = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(percent: 99)]))
        let threeDigitImage = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(percent: 100)]))

        #expect(threeDigitImage.size.width > twoDigitImage.size.width)
    }

    @Test
    func `compact usage display expands for five hour and seven day percentages`() throws {
        let singleImage = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(percent: 60)]))
        let dualImage = try #require(
            MenuBarCompactUsageRenderer.image(entries: [self.entry(percent: 60, secondaryPercent: 53)]))

        #expect(dualImage.size.width > singleImage.size.width)
    }

    @Test
    func `compact usage display leaves trailing breathing room for three digit percentages`() throws {
        let image = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(percent: 100)]))

        #expect(!self.columnHasVisiblePixels(image, x: Int(image.size.width) - 1))
    }

    @Test
    func `compact usage display expands for wider provider codes`() throws {
        let defaultCodeImage = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(code: "cx")]))
        let wideCodeImage = try #require(MenuBarCompactUsageRenderer.image(entries: [self.entry(code: "ocg")]))

        #expect(wideCodeImage.size.width > defaultCodeImage.size.width)
    }

    @Test
    func `compact usage display expands status item length for three digit percentages`() throws {
        let settings = SettingsStore(
            configStore: testConfigStore(suiteName: "MenuBarCompactUsageRendererTests-status-item-width"),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
        settings.statusChecksEnabled = false
        settings.refreshFrequency = .manual
        settings.mergeIcons = true
        settings.menuBarShowsBrandIconWithPercent = true
        settings.menuBarUsageDisplayStyle = .compactBars
        settings.usageBarsShowUsed = true

        let registry = ProviderRegistry.shared
        if let codexMeta = registry.metadata[.codex] {
            settings.setProviderEnabled(provider: .codex, metadata: codexMeta, enabled: true)
        }

        let fetcher = UsageFetcher()
        let store = UsageStore(fetcher: fetcher, browserDetection: BrowserDetection(cacheTTL: 0), settings: settings)
        let controller = StatusItemController(
            store: store,
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: self.makeStatusBarForTesting())
        store._setSnapshotForTesting(
            UsageSnapshot(
                primary: RateWindow(usedPercent: 100, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
                secondary: nil,
                updatedAt: Date()),
            provider: .codex)

        controller.applyIcon(phase: nil)

        let image = try #require(controller.statusItem.button?.image)
        #expect(controller.statusItem.length == StatusItemController.compactStatusItemLength(for: image))
        #expect(controller.statusItem.length > image.size.width)
    }
}
