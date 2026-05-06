import AppKit
import CodexBarCore
import CodexBarMacroSupport
import Foundation

@ProviderImplementationRegistration
struct SyntheticProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .synthetic

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { _ in "api" }
    }

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.syntheticAPIToken
    }

    @MainActor
    func isAvailable(context: ProviderAvailabilityContext) -> Bool {
        if SyntheticSettingsReader.apiKey(environment: context.environment) != nil {
            return true
        }
        context.settings.ensureSyntheticAPITokenLoaded()
        return !context.settings.syntheticAPIToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "synthetic-api-key",
                title: L10n.string("API key"),
                subtitle: L10n.string("Stored Synthetic API key notice"),
                kind: .secure,
                placeholder: "Paste key…",
                binding: context.stringBinding(\.syntheticAPIToken),
                actions: [],
                isVisible: nil,
                onActivate: { context.settings.ensureSyntheticAPITokenLoaded() }),
        ]
    }
}
