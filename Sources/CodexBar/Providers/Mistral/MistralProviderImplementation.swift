import AppKit
import CodexBarCore
import Foundation
import SwiftUI

struct MistralProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .mistral

    @MainActor
    func presentation(context _: ProviderPresentationContext) -> ProviderPresentation {
        ProviderPresentation { _ in "web" }
    }

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.mistralCookieSource
        _ = settings.mistralCookieHeader
    }

    @MainActor
    func settingsSnapshot(context: ProviderSettingsSnapshotContext) -> ProviderSettingsSnapshotContribution? {
        .mistral(context.settings.mistralSettingsSnapshot(tokenOverride: context.tokenOverride))
    }

    @MainActor
    func tokenAccountsVisibility(context: ProviderSettingsContext, support: TokenAccountSupport) -> Bool {
        guard support.requiresManualCookieSource else { return true }
        if !context.settings.tokenAccounts(for: context.provider).isEmpty { return true }
        return context.settings.mistralCookieSource == .manual
    }

    @MainActor
    func applyTokenAccountCookieSource(settings: SettingsStore) {
        if settings.mistralCookieSource != .manual {
            settings.mistralCookieSource = .manual
        }
    }

    @MainActor
    func settingsPickers(context: ProviderSettingsContext) -> [ProviderSettingsPickerDescriptor] {
        let cookieBinding = Binding(
            get: { context.settings.mistralCookieSource.rawValue },
            set: { raw in
                context.settings.mistralCookieSource = ProviderCookieSource(rawValue: raw) ?? .auto
            })
        let cookieOptions = ProviderCookieSourceUI.options(
            allowsOff: false,
            keychainDisabled: context.settings.debugDisableKeychainAccess)

        let cookieSubtitle: () -> String? = {
            ProviderCookieSourceUI.subtitle(
                source: context.settings.mistralCookieSource,
                keychainDisabled: context.settings.debugDisableKeychainAccess,
                auto: L10n.string("Automatic imports browser cookies from admin.mistral.ai."),
                manual: L10n.string("Paste a Cookie header captured from the billing page."),
                off: L10n.string("Mistral cookies are disabled."))
        }

        return [
            ProviderSettingsPickerDescriptor(
                id: "mistral-cookie-source",
                title: L10n.string("Cookie source"),
                subtitle: L10n.string("Automatic imports browser cookies from admin.mistral.ai."),
                dynamicSubtitle: cookieSubtitle,
                binding: cookieBinding,
                options: cookieOptions,
                isVisible: nil,
                onChange: nil,
                trailingText: {
                    ProviderCookieSourceUI.cachedTrailingText(provider: .mistral)
                }),
        ]
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "mistral-cookie-header",
                title: L10n.string("Cookie header"),
                subtitle: L10n.string("Paste Mistral cookie header notice"),
                kind: .secure,
                placeholder: "ory_session_…=…; csrftoken=…",
                binding: context.stringBinding(\.mistralCookieHeader),
                actions: [
                    ProviderSettingsActionDescriptor(
                        id: "mistral-open-console",
                        title: L10n.string("Open Mistral Admin"),
                        style: .link,
                        isVisible: nil,
                        perform: {
                            if let url = URL(string: "https://admin.mistral.ai/organization/usage") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                ],
                isVisible: { context.settings.mistralCookieSource == .manual },
                onActivate: nil),
        ]
    }
}
