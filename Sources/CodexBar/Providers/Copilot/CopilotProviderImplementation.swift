import AppKit
import CodexBarCore
import CodexBarMacroSupport
import SwiftUI

@ProviderImplementationRegistration
struct CopilotProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .copilot
    let supportsLoginFlow: Bool = true

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { _ in "github api" }
    }

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.copilotAPIToken
    }

    @MainActor
    func settingsSnapshot(context: ProviderSettingsSnapshotContext) -> ProviderSettingsSnapshotContribution? {
        .copilot(context.settings.copilotSettingsSnapshot(tokenOverride: context.tokenOverride))
    }

    @MainActor
    func loginMenuAction(context _: ProviderMenuLoginContext)
        -> (label: String, action: MenuDescriptor.MenuAction)?
    {
        (L10n.string("menu.addAccount"), .addProviderAccount(.copilot))
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "copilot-add-account",
                title: L10n.string("GitHub Login"),
                subtitle: L10n.string("Add accounts via GitHub OAuth Device Flow."),
                kind: .plain,
                placeholder: nil,
                binding: .constant(""),
                actions: [
                    ProviderSettingsActionDescriptor(
                        id: "copilot-add-account-action",
                        title: L10n.string("Add Account"),
                        style: .bordered,
                        isVisible: { true },
                        perform: {
                            await CopilotLoginFlow.run(settings: context.settings)
                        }),
                ],
                isVisible: nil,
                onActivate: nil),
        ]
    }

    @MainActor
    func runLoginFlow(context: ProviderLoginContext) async -> Bool {
        await CopilotLoginFlow.run(settings: context.controller.settings)
        return true
    }
}
