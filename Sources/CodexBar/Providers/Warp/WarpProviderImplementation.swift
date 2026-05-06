import AppKit
import CodexBarCore
import CodexBarMacroSupport
import Foundation

@ProviderImplementationRegistration
struct WarpProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .warp

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.warpAPIToken
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "warp-api-token",
                title: L10n.string("API key"),
                subtitle: L10n.string("Stored Warp API key notice"),
                kind: .secure,
                placeholder: "wk-...",
                binding: context.stringBinding(\.warpAPIToken),
                actions: [
                    ProviderSettingsActionDescriptor(
                        id: "warp-open-api-keys",
                        title: L10n.string("Open Warp API Key Guide"),
                        style: .link,
                        isVisible: nil,
                        perform: {
                            if let url = URL(string: "https://docs.warp.dev/reference/cli/api-keys") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                ],
                isVisible: nil,
                onActivate: nil),
        ]
    }
}
