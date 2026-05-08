import AppKit
import CodexBarCore
import Foundation

extension ProviderColor {
    fileprivate var nsColor: NSColor {
        NSColor(
            calibratedRed: CGFloat(self.red),
            green: CGFloat(self.green),
            blue: CGFloat(self.blue),
            alpha: 1)
    }
}

@MainActor
enum ProviderNotificationAttachment {
    private static let iconSize = NSSize(width: 128, height: 128)
    private static let iconInset: CGFloat = 22

    static func fileURL(
        for provider: UsageProvider,
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil) -> URL?
    {
        guard let sourceURL = ProviderBrandIcon.resourceURL(for: provider),
              let icon = NSImage(contentsOf: sourceURL),
              let pngData = self.pngData(for: icon, provider: provider)
        else {
            return nil
        }

        let directory = baseDirectory ?? fileManager.temporaryDirectory
            .appending(path: "CodexBarNotificationAttachments", directoryHint: .isDirectory)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appending(path: "\(provider.rawValue)-notification.png")
            try pngData.write(to: url, options: .atomic)
            return url
        } catch {
            CodexBarLog.logger(LogCategories.notifications).debug(
                "failed to prepare provider notification attachment",
                metadata: ["provider": provider.rawValue, "error": String(describing: error)])
            return nil
        }
    }

    private static func pngData(for icon: NSImage, provider: UsageProvider) -> Data? {
        let output = NSImage(size: self.iconSize)
        let rect = NSRect(origin: .zero, size: self.iconSize)
        let descriptor = ProviderDescriptorRegistry.descriptor(for: provider)

        output.lockFocus()
        NSColor.clear.setFill()
        rect.fill()

        let background = NSBezierPath(
            roundedRect: rect.insetBy(dx: 8, dy: 8),
            xRadius: 24,
            yRadius: 24)
        descriptor.branding.color.nsColor.withAlphaComponent(0.16).setFill()
        background.fill()

        icon.draw(
            in: rect.insetBy(dx: self.iconInset, dy: self.iconInset),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .sourceOver,
            fraction: 1)
        output.unlockFocus()

        guard let tiff = output.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
