import CodexBarCore
import CodexBarMacroSupport
import SwiftUI

@ProviderImplementationRegistration
struct ClaudeProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .claude
    let supportsLoginFlow: Bool = true

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { context in
            var versionText = context.store.version(for: context.provider) ?? L10n.string("not detected")
            if let parenRange = versionText.range(of: "(") {
                versionText = versionText[..<parenRange.lowerBound].trimmingCharacters(in: .whitespaces)
            }
            return "\(context.metadata.cliName) \(versionText)"
        }
    }

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.claudeUsageDataSource
        // Claude Code peak-hours policy was retired; keep the stored preference inert.
        // _ = settings.claudePeakHoursEnabled
    }

    @MainActor
    func settingsSnapshot(context: ProviderSettingsSnapshotContext) -> ProviderSettingsSnapshotContribution? {
        .claude(context.settings.claudeSettingsSnapshot(tokenOverride: context.tokenOverride))
    }

    @MainActor
    func tokenAccountsVisibility(context: ProviderSettingsContext, support: TokenAccountSupport) -> Bool {
        _ = context
        _ = support
        return false
    }

    @MainActor
    func applyTokenAccountCookieSource(settings _: SettingsStore) {}

    @MainActor
    func defaultSourceLabel(context: ProviderSourceLabelContext) -> String? {
        context.settings.claudeUsageDataSource.rawValue
    }

    @MainActor
    func sourceMode(context: ProviderSourceModeContext) -> ProviderSourceMode {
        switch context.settings.claudeUsageDataSource {
        case .auto: .auto
        case .cli: .cli
        case .log: .log
        case .oauth, .web: .auto
        }
    }

    @MainActor
    func settingsToggles(context: ProviderSettingsContext) -> [ProviderSettingsToggleDescriptor] {
        _ = context
        // Claude Code peak-hours policy was retired; do not expose the old toggle.
        return []
    }

    @MainActor
    func settingsPickers(context: ProviderSettingsContext) -> [ProviderSettingsPickerDescriptor] {
        let usageBinding = Binding(
            get: { context.settings.claudeUsageDataSource.rawValue },
            set: { raw in
                context.settings.claudeUsageDataSource = ClaudeUsageDataSource(rawValue: raw) ?? .auto
            })
        let usageOptions = ClaudeUsageDataSource.supportedClaudeCodeSources.map {
            ProviderSettingsPickerOption(id: $0.rawValue, title: L10n.optionLabel($0.displayName))
        }

        return [
            ProviderSettingsPickerDescriptor(
                id: "claude-usage-source",
                title: L10n.string("Usage source"),
                subtitle: L10n.string(
                    "Auto uses the Claude CLI first, then local logs. No web or OAuth usage requests."),
                binding: usageBinding,
                options: usageOptions,
                isVisible: nil,
                onChange: nil,
                trailingText: {
                    guard context.settings.claudeUsageDataSource == .auto else { return nil }
                    let label = context.store.sourceLabel(for: .claude)
                    return label == "auto" ? nil : label
                }),
        ]
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        _ = context
        return []
    }

    @MainActor
    func runLoginFlow(context: ProviderLoginContext) async -> Bool {
        await context.controller.runClaudeLoginFlow()
    }

    @MainActor
    func appendUsageMenuEntries(context: ProviderMenuUsageContext, entries: inout [ProviderMenuEntry]) {
        if context.snapshot?.secondary == nil {
            entries.append(.text(L10n.string("Weekly usage unavailable for this account."), .secondary))
        }

        if let cost = context.snapshot?.providerCost,
           context.settings.showOptionalCreditsAndExtraUsage,
           cost.currencyCode != "Quota"
        {
            let used = UsageFormatter.currencyString(cost.used, currencyCode: cost.currencyCode)
            let limit = UsageFormatter.currencyString(cost.limit, currencyCode: cost.currencyCode)
            entries.append(.text(L10n.string("Extra usage line format", used, limit), .primary))
        }
    }

    @MainActor
    func loginMenuAction(context: ProviderMenuLoginContext)
        -> (label: String, action: MenuDescriptor.MenuAction)?
    {
        guard self.shouldOpenTerminalForOAuthError(store: context.store) else { return nil }
        return (L10n.string("Open Terminal"), .openTerminal(command: "claude"))
    }

    @MainActor
    private func shouldOpenTerminalForOAuthError(store: UsageStore) -> Bool {
        guard store.error(for: .claude) != nil else { return false }
        let attempts = store.fetchAttempts(for: .claude)
        if attempts.contains(where: { $0.kind == .oauth && ($0.errorDescription?.isEmpty == false) }) {
            return true
        }
        if let error = store.error(for: .claude)?.lowercased(), error.contains("oauth") {
            return true
        }
        return false
    }
}
