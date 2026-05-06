import Foundation

enum MenuBarUsageDisplayStyle: String, CaseIterable, Identifiable {
    case iconPercent
    case compactBars

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .iconPercent: L10n.string("menuBarUsageDisplay.iconPercent")
        case .compactBars: L10n.string("menuBarUsageDisplay.compactBars")
        }
    }

    var description: String {
        switch self {
        case .iconPercent: L10n.string("menuBarUsageDisplay.iconPercent.description")
        case .compactBars: L10n.string("menuBarUsageDisplay.compactBars.description")
        }
    }
}
