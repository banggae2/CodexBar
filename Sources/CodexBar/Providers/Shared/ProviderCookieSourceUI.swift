import CodexBarCore

enum ProviderCookieSourceUI {
    static let keychainDisabledPrefix =
        L10n.string("Keychain access disabled cookie import unavailable")

    static func options(allowsOff: Bool, keychainDisabled: Bool) -> [ProviderSettingsPickerOption] {
        var options: [ProviderSettingsPickerOption] = []
        if !keychainDisabled {
            options.append(ProviderSettingsPickerOption(
                id: ProviderCookieSource.auto.rawValue,
                title: L10n.optionLabel(ProviderCookieSource.auto.displayName)))
        }
        options.append(ProviderSettingsPickerOption(
            id: ProviderCookieSource.manual.rawValue,
            title: L10n.optionLabel(ProviderCookieSource.manual.displayName)))
        if allowsOff {
            options.append(ProviderSettingsPickerOption(
                id: ProviderCookieSource.off.rawValue,
                title: L10n.optionLabel(ProviderCookieSource.off.displayName)))
        }
        return options
    }

    static func subtitle(
        source: ProviderCookieSource,
        keychainDisabled: Bool,
        auto: String,
        manual: String,
        off: String) -> String
    {
        if keychainDisabled {
            return source == .off ? off : "\(self.keychainDisabledPrefix) \(manual)"
        }
        switch source {
        case .auto:
            return auto
        case .manual:
            return manual
        case .off:
            return off
        }
    }
}
