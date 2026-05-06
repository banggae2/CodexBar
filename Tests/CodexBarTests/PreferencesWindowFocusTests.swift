import AppKit
import Testing
@testable import CodexBar

@Suite(.serialized)
@MainActor
struct PreferencesWindowFocusTests {
    @Test
    func `finds settings window by SwiftUI settings identifier`() {
        let hiddenWindow = NSWindow()
        hiddenWindow.title = "CodexBarLifecycleKeepalive"

        let settingsWindow = NSWindow()
        settingsWindow.identifier = NSUserInterfaceItemIdentifier(PreferencesWindowFocus.settingsWindowIdentifier)

        #expect(PreferencesWindowFocus.settingsWindow(in: [hiddenWindow, settingsWindow]) === settingsWindow)
    }

    @Test
    func `finds settings window by localized tab title`() {
        let settingsWindow = NSWindow()
        settingsWindow.title = PreferencesTab.notifications.title

        #expect(PreferencesWindowFocus.settingsWindow(in: [settingsWindow]) === settingsWindow)
    }

    @Test
    func `prefers keyable settings window over non keyable title match`() {
        let nonKeyableWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        nonKeyableWindow.title = PreferencesTab.notifications.title

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false)
        settingsWindow.title = PreferencesTab.notifications.title

        #expect(PreferencesWindowFocus.settingsWindow(in: [nonKeyableWindow, settingsWindow]) === settingsWindow)
    }
}
