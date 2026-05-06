import AppKit
import CodexBarCore
import CodexBarMacroSupport
import Foundation
import SwiftUI

@ProviderImplementationRegistration
struct KiloProviderImplementation: ProviderImplementation {
    let id: UsageProvider = .kilo

    @MainActor
    func observeSettings(_ settings: SettingsStore) {
        _ = settings.kiloUsageDataSource
        _ = settings.kiloExtrasEnabled
        _ = settings.kiloAPIToken
    }

    @MainActor
    func isAvailable(context _: ProviderAvailabilityContext) -> Bool {
        // Keep availability permissive to avoid main-thread auth-file I/O while still showing Kilo for auth.json-only
        // setups. Fetch-time auth resolution remains authoritative (env first, then auth file fallback).
        true
    }

    @MainActor
    func settingsSnapshot(context: ProviderSettingsSnapshotContext) -> ProviderSettingsSnapshotContribution? {
        .kilo(context.settings.kiloSettingsSnapshot(tokenOverride: context.tokenOverride))
    }

    @MainActor
    func defaultSourceLabel(context: ProviderSourceLabelContext) -> String? {
        context.settings.kiloUsageDataSource.rawValue
    }

    @MainActor
    func sourceMode(context: ProviderSourceModeContext) -> ProviderSourceMode {
        switch context.settings.kiloUsageDataSource {
        case .auto: .auto
        case .api: .api
        case .cli: .cli
        }
    }

    @MainActor
    func settingsPickers(context: ProviderSettingsContext) -> [ProviderSettingsPickerDescriptor] {
        let usageBinding = Binding(
            get: { context.settings.kiloUsageDataSource.rawValue },
            set: { raw in
                context.settings.kiloUsageDataSource = KiloUsageDataSource(rawValue: raw) ?? .auto
            })
        let usageOptions = KiloUsageDataSource.allCases.map {
            ProviderSettingsPickerOption(id: $0.rawValue, title: L10n.optionLabel($0.displayName))
        }
        return [
            ProviderSettingsPickerDescriptor(
                id: "kilo-usage-source",
                title: L10n.string("Usage source"),
                subtitle: L10n.string("Auto uses API first, then falls back to CLI on auth failures."),
                binding: usageBinding,
                options: usageOptions,
                isVisible: nil,
                onChange: nil,
                trailingText: {
                    guard context.settings.kiloUsageDataSource == .auto else { return nil }
                    let label = context.store.sourceLabel(for: .kilo)
                    return label == "auto" ? nil : label
                }),
        ]
    }

    @MainActor
    func settingsFields(context: ProviderSettingsContext) -> [ProviderSettingsFieldDescriptor] {
        [
            ProviderSettingsFieldDescriptor(
                id: "kilo-api-key",
                title: L10n.string("API key"),
                subtitle: L10n.string("Stored Kilo API key notice"),
                kind: .secure,
                placeholder: "kilo_...",
                binding: context.stringBinding(\.kiloAPIToken),
                actions: [],
                isVisible: nil,
                onActivate: nil),
        ]
    }
}
