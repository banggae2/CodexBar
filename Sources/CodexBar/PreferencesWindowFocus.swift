import AppKit
import CodexBarCore

@MainActor
enum PreferencesWindowFocus {
    static let settingsWindowIdentifier = "com_apple_SwiftUI_Settings_window"

    private static var knownTabTitles: Set<String> {
        let fixedPanes: [SettingsPane] = [
            .general,
            .notifications,
            .menuBar,
            .menu,
            .advanced,
            .about,
            .debug,
        ]
        let providerPanes = UsageProvider.allCases.map(SettingsPane.provider)
        return Set((fixedPanes + providerPanes).map(\.title))
    }

    static func settingsWindow(in windows: [NSWindow] = NSApp.windows) -> NSWindow? {
        let candidates = windows.filter { window in
            window.identifier?.rawValue == self.settingsWindowIdentifier
                || self.knownTabTitles.contains(window.title)
        }
        return candidates.first(where: \.canBecomeKey) ?? candidates.first
    }

    static func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        self.focusSettingsWindow()
        self.focusSettingsWindowDeferred()
    }

    static func focusSettingsWindowDeferred(attempts: Int = 6) {
        guard attempts > 0 else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            if !self.focusSettingsWindow() {
                self.focusSettingsWindowDeferred(attempts: attempts - 1)
            }
        }
    }

    @discardableResult
    static func focusSettingsWindow() -> Bool {
        NSApp.activate(ignoringOtherApps: true)
        guard let window = self.settingsWindow() else { return false }

        window.makeKeyAndOrderFront(nil)
        if window.canBecomeMain {
            window.makeMain()
        }
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        return NSApp.isActive && window.isKeyWindow
    }
}
