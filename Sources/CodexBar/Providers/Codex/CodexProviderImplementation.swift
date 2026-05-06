import CodexBarCore
import CodexBarMacroSupport
import Foundation
import SwiftUI

@ProviderImplementationRegistration
struct CodexProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .codex
    let supportsLoginFlow: Bool = true

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { context in
            context.store.version(for: context.provider) ?? L10n.string("not detected")
        }
    }

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.codexUsageDataSource
        _ = settings.codexCookieSource
        _ = settings.codexCookieHeader
    }

    @MainActor
    func settingsSnapshot(context: ProviderSettingsSnapshotContext) -> ProviderSettingsSnapshotContribution? {
        .codex(context.settings.codexSettingsSnapshot(tokenOverride: context.tokenOverride))
    }

    @MainActor
    func defaultSourceLabel(context: ProviderSourceLabelContext) -> String? {
        context.settings.codexUsageDataSource.rawValue
    }

    @MainActor
    func decorateSourceLabel(context: ProviderSourceLabelContext, baseLabel: String) -> String {
        if context.settings.codexCookieSource.isEnabled,
           context.store.openAIDashboard != nil,
           !context.store.openAIDashboardRequiresLogin,
           !baseLabel.contains("openai-web")
        {
            return "\(baseLabel) + openai-web"
        }
        return baseLabel
    }

    @MainActor
    func sourceMode(context: ProviderSourceModeContext) -> ProviderSourceMode {
        switch context.settings.codexUsageDataSource {
        case .auto: .auto
        case .oauth: .oauth
        case .cli: .cli
        }
    }

    func makeRuntime() -> (any ProviderRuntime)? {
        CodexProviderRuntime()
    }

    @MainActor
    func settingsToggles(context: ProviderSettingsContext) -> [ProviderSettingsToggleDescriptor] {
        let extrasBinding = Binding(
            get: { context.settings.openAIWebAccessEnabled },
            set: { enabled in
                context.settings.openAIWebAccessEnabled = enabled
                Task { @MainActor in
                    await context.store.performRuntimeAction(
                        .openAIWebAccessToggled(enabled),
                        for: .codex)
                }
            })
        let batterySaverBinding = context.boolBinding(\.openAIWebBatterySaverEnabled)

        return [
            ProviderSettingsToggleDescriptor(
                id: "codex-historical-tracking",
                title: L10n.string("Historical tracking"),
                subtitle: L10n.string("Stores local Codex usage history to personalize Pace predictions."),
                binding: context.boolBinding(\.historicalTrackingEnabled),
                statusText: nil,
                actions: [],
                isVisible: nil,
                onChange: nil,
                onAppDidBecomeActive: nil,
                onAppearWhenEnabled: nil),
            ProviderSettingsToggleDescriptor(
                id: "codex-openai-web-extras",
                title: L10n.string("OpenAI web extras"),
                subtitle: [
                    L10n.string("Optional."),
                    L10n
                        .string(
                            "Turn this on to show code review, usage breakdown, and credits history via chatgpt.com."),
                ].joined(separator: " "),
                binding: extrasBinding,
                statusText: nil,
                actions: [],
                isVisible: nil,
                onChange: nil,
                onAppDidBecomeActive: nil,
                onAppearWhenEnabled: nil),
            ProviderSettingsToggleDescriptor(
                id: "codex-openai-web-battery-saver",
                title: L10n.string("Battery Saver"),
                subtitle: [
                    L10n.string("Limits background chatgpt.com refreshes to reduce battery and network usage."),
                    L10n.string("Dashboard extras may stay stale until you refresh them manually."),
                ].joined(separator: " "),
                binding: batterySaverBinding,
                statusText: nil,
                actions: [],
                isVisible: { context.settings.openAIWebAccessEnabled },
                onChange: nil,
                onAppDidBecomeActive: nil,
                onAppearWhenEnabled: nil),
        ]
    }

    @MainActor
    func settingsPickers(context: ProviderSettingsContext) -> [ProviderSettingsPickerDescriptor] {
        let usageBinding = Binding(
            get: { context.settings.codexUsageDataSource.rawValue },
            set: { raw in
                context.settings.codexUsageDataSource = CodexUsageDataSource(rawValue: raw) ?? .auto
            })
        let cookieBinding = Binding(
            get: { context.settings.codexCookieSource.rawValue },
            set: { raw in
                context.settings.codexCookieSource = ProviderCookieSource(rawValue: raw) ?? .auto
            })

        let usageOptions = CodexUsageDataSource.allCases.map {
            ProviderSettingsPickerOption(id: $0.rawValue, title: L10n.optionLabel($0.displayName))
        }
        let cookieOptions = ProviderCookieSourceUI.options(
            allowsOff: true,
            keychainDisabled: context.settings.debugDisableKeychainAccess)

        let cookieSubtitle: () -> String? = {
            ProviderCookieSourceUI.subtitle(
                source: context.settings.codexCookieSource,
                keychainDisabled: context.settings.debugDisableKeychainAccess,
                auto: L10n.string("Automatic imports browser cookies for dashboard extras."),
                manual: L10n.string("Paste a Cookie header from a chatgpt.com request."),
                off: L10n.string("Disable OpenAI dashboard cookie usage."))
        }

        return [
            ProviderSettingsPickerDescriptor(
                id: "codex-usage-source",
                title: L10n.string("Usage source"),
                subtitle: L10n.string("Auto falls back to the next source if the preferred one fails."),
                binding: usageBinding,
                options: usageOptions,
                isVisible: nil,
                onChange: nil,
                trailingText: {
                    guard context.settings.codexUsageDataSource == .auto else { return nil }
                    let label = context.store.sourceLabel(for: .codex)
                    return label == "auto" ? nil : label
                }),
            ProviderSettingsPickerDescriptor(
                id: "codex-cookie-source",
                title: L10n.string("OpenAI cookies"),
                subtitle: L10n.string("Automatic imports browser cookies for dashboard extras."),
                dynamicSubtitle: cookieSubtitle,
                binding: cookieBinding,
                options: cookieOptions,
                isVisible: { context.settings.openAIWebAccessEnabled },
                onChange: nil,
                trailingText: {
                    guard let entry = CookieHeaderCache.load(provider: .codex) else { return nil }
                    let when = entry.storedAt.relativeDescription()
                    return L10n.string("Cached source time format", entry.sourceLabel, when)
                }),
        ]
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "codex-cookie-header",
                title: "",
                subtitle: "",
                kind: .secure,
                placeholder: "Cookie: …",
                binding: context.stringBinding(\.codexCookieHeader),
                actions: [],
                isVisible: {
                    context.settings.codexCookieSource == .manual
                },
                onActivate: { context.settings.ensureCodexCookieLoaded() }),
        ]
    }

    @MainActor
    func appendUsageMenuEntries(context: ProviderMenuUsageContext, entries: inout [ProviderMenuEntry]) {
        guard context.settings.showOptionalCreditsAndExtraUsage,
              context.metadata.supportsCredits
        else { return }

        if let credits = context.store.credits {
            entries.append(.text(
                L10n.string("Credits line format", AppUsageFormatter.creditsString(from: credits.remaining)),
                .primary))
            if let latest = credits.events.first {
                entries.append(.text(
                    L10n.string("Last spend format", AppUsageFormatter.creditEventSummary(latest)),
                    .secondary))
            }
        } else {
            let hint = context.store.userFacingLastCreditsError ?? context.metadata.creditsHint
            entries.append(.text(hint, .secondary))
        }
    }

    @MainActor
    func loginMenuAction(context _: ProviderMenuLoginContext)
        -> (label: String, action: MenuDescriptor.MenuAction)?
    {
        (L10n.string("menu.addAccount"), .addCodexAccount)
    }

    @MainActor
    func appendActionMenuEntries(context: ProviderMenuActionContext, entries: inout [ProviderMenuEntry]) {
        let projection = context.settings.codexVisibleAccountProjection
        guard !projection.visibleAccounts.isEmpty else { return }

        let isInteractionBlocked = context.codexAccountPromotionCoordinator?.isInteractionBlocked() ?? false

        let submenuItems = projection.visibleAccounts.map { account in
            let isChecked = account.id == projection.liveVisibleAccountID
            let isEnabled = !isInteractionBlocked &&
                !isChecked &&
                account.storedAccountID != nil
            let action = account.storedAccountID.map(MenuDescriptor.MenuAction.requestCodexSystemPromotion)
            return MenuDescriptor.SubmenuItem(
                title: account.displayName,
                action: action,
                isEnabled: isEnabled,
                isChecked: isChecked)
        }

        entries.append(.submenu(
            L10n.string("System Account"),
            MenuDescriptor.MenuActionSystemImage.systemAccount.rawValue,
            submenuItems))
    }

    @MainActor
    func runLoginFlow(context: ProviderLoginContext) async -> Bool {
        await context.controller.runCodexLoginFlow()
        return true
    }
}
