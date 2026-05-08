import AppKit
import CodexBarCore

enum ProviderBrandIcon {
    private static let size = NSSize(width: 16, height: 16)

    /// Lazy-loaded resource bundle for provider icons.
    private static let resourceBundle: Bundle? = {
        // SwiftPM creates a CodexBar_CodexBar.bundle for resources in the CodexBar target.
        if let bundleURL = Bundle.main.url(forResource: "CodexBar_CodexBar", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL)
        {
            return bundle
        }
        // Fallback to main bundle for development/testing.
        return Bundle.main
    }()

    static func resourceURL(for provider: UsageProvider) -> URL? {
        let baseName = ProviderDescriptorRegistry.descriptor(for: provider).branding.iconResourceName
        return self.resourceBundle?.url(forResource: baseName, withExtension: "svg")
    }

    static func image(for provider: UsageProvider) -> NSImage? {
        guard let url = self.resourceURL(for: provider),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.size = self.size
        image.isTemplate = true
        return image
    }
}
