import AppKit
import Foundation

enum SystemSettingsLinks {
    /// Opens System Settings → Notifications (best effort).
    static func openNotifications(bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
        let appSpecificURLs = bundleIdentifier.map { identifier in
            [
                URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(identifier)"),
                URL(string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(identifier)"),
            ].compactMap(\.self)
        } ?? []

        let urls = appSpecificURLs + [
            URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"),
            URL(string: "x-apple.systempreferences:com.apple.preference.notifications"),
        ].compactMap(\.self)

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }

    /// Opens System Settings → Privacy & Security → Full Disk Access (best effort).
    static func openFullDiskAccess() {
        // Best-effort deep link. On older betas it sometimes opened the wrong pane; on modern macOS this is stable.
        let urls: [URL] = [
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security"),
        ].compactMap(\.self)

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }
}
