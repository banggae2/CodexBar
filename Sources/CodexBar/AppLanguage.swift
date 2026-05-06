import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case korean

    static let userDefaultsKey = "appLanguage"

    var id: String {
        self.rawValue
    }

    var localeIdentifier: String? {
        switch self {
        case .system: nil
        case .english: "en"
        case .korean: "ko"
        }
    }

    var displayName: String {
        switch self {
        case .system: L10n.string("System Default")
        case .english: L10n.string("English")
        case .korean: L10n.string("Korean")
        }
    }
}
