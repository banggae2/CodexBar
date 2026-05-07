import Foundation

public enum ClaudePeakHours: Sendable {
    public struct Status: Sendable, Equatable {
        public let isPeak: Bool
        public let label: String
        public let minutesUntilTransition: Int
    }

    public static func status(at _: Date) -> Status {
        // Claude Code peak-hours policy was retired; callers should treat this as inactive.
        Status(isPeak: false, label: "Peak hours retired", minutesUntilTransition: 0)
    }
}
