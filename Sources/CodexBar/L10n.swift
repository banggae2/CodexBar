import Foundation

enum L10n {
    static var locale: Locale {
        Locale(identifier: self.appLocaleIdentifier() ?? Locale.current.identifier)
    }

    static func string(_ key: String, localeIdentifier: String? = nil) -> String {
        let bundle = self.bundle(localeIdentifier: localeIdentifier ?? self.appLocaleIdentifier())
        let localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        if localized != key {
            return localized
        }
        return self.developmentBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func string(_ key: String, _ arguments: CVarArg..., localeIdentifier: String? = nil) -> String {
        let format = self.string(key, localeIdentifier: localeIdentifier)
        let locale = Locale(identifier: localeIdentifier ?? self.appLocaleIdentifier() ?? Locale.current.identifier)
        return String(format: format, locale: locale, arguments: arguments)
    }

    static func metricLabel(_ raw: String) -> String {
        let key = "metric.\(raw)"
        let localized = self.string(key)
        return localized == key ? raw : localized
    }

    static func optionLabel(_ raw: String) -> String {
        let key = "option.\(raw)"
        let localized = self.string(key)
        return localized == key ? raw : localized
    }

    private static let developmentLanguage = "en"

    private static func appLocaleIdentifier() -> String? {
        if let override = CodexBarLocalizationOverride.appLanguage,
           let language = AppLanguage(rawValue: override)
        {
            return language.localeIdentifier
        }
        guard let raw = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey),
              let language = AppLanguage(rawValue: raw)
        else { return nil }
        return language.localeIdentifier
    }

    private static var developmentBundle: Bundle {
        guard let path = Bundle.module.path(forResource: self.developmentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path)
        else {
            return .module
        }
        return bundle
    }

    private static func bundle(localeIdentifier: String?) -> Bundle {
        guard let localeIdentifier else {
            return .module
        }
        let locale = Locale(identifier: localeIdentifier)
        let candidates = [
            locale.identifier,
            locale.language.languageCode?.identifier,
        ].compactMap(\.self)

        for candidate in candidates {
            if let path = Bundle.module.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path)
            {
                return bundle
            }
        }
        return self.developmentBundle
    }
}
