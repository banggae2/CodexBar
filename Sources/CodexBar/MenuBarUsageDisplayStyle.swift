import Foundation

enum MenuBarUsageDisplayStyle: String, CaseIterable, Identifiable {
    case iconPercent
    case compactBars

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .iconPercent: L("menuBarUsageDisplay.iconPercent")
        case .compactBars: L("menuBarUsageDisplay.compactBars")
        }
    }

    var description: String {
        switch self {
        case .iconPercent: L("menuBarUsageDisplay.iconPercent.description")
        case .compactBars: L("menuBarUsageDisplay.compactBars.description")
        }
    }
}
