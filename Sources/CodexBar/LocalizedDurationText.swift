import Foundation

enum LocalizedDurationText {
    static func valueDescription(seconds: TimeInterval) -> String {
        if seconds < 1 { return L10n.string("Duration now") }
        return self.valueDescription(minutes: max(1, Int(ceil(seconds / 60.0))))
    }

    static func valueDescription(minutes totalMinutes: Int) -> String {
        let clampedMinutes = max(1, totalMinutes)
        let days = clampedMinutes / (24 * 60)
        let hours = (clampedMinutes / 60) % 24
        let minutes = clampedMinutes % 60

        if days > 0 {
            if hours > 0 { return L10n.string("Duration value days hours format", days, hours) }
            return L10n.string("Duration value days format", days)
        }
        if hours > 0 {
            if minutes > 0 { return L10n.string("Duration value hours minutes format", hours, minutes) }
            return L10n.string("Duration value hours format", hours)
        }
        return L10n.string("Duration value minutes format", clampedMinutes)
    }

    static func futureDescription(seconds: TimeInterval) -> String {
        if seconds < 1 { return L10n.string("Duration now") }
        return self.futureDescription(minutes: max(1, Int(ceil(seconds / 60.0))))
    }

    static func futureDescription(minutes totalMinutes: Int) -> String {
        L10n.string("Duration future format", self.valueDescription(minutes: totalMinutes))
    }
}
