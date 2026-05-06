import Foundation

/// Controls what the menu bar displays when brand icon mode is enabled.
enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case percent
    case pace
    case both

    var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .percent: L10n.string("menuBarDisplay.percent")
        case .pace: L10n.string("menuBarDisplay.pace")
        case .both: L10n.string("menuBarDisplay.both")
        }
    }

    var description: String {
        switch self {
        case .percent: L10n.string("menuBarDisplay.percent.description")
        case .pace: L10n.string("menuBarDisplay.pace.description")
        case .both: L10n.string("menuBarDisplay.both.description")
        }
    }
}
