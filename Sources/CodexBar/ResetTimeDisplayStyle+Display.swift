import CodexBarCore
import Foundation

extension ResetTimeDisplayStyle: CaseIterable, Identifiable {
    public static var allCases: [ResetTimeDisplayStyle] {
        [.countdown, .absolute, .both]
    }

    public var id: String {
        self.rawValue
    }

    var label: String {
        switch self {
        case .countdown:
            L10n.string("resetTimeDisplay.countdown")
        case .absolute:
            L10n.string("resetTimeDisplay.absolute")
        case .both:
            L10n.string("resetTimeDisplay.both")
        }
    }
}
