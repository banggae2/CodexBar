import Foundation

enum RelativeTimeFormatters {
    @MainActor
    static func full(locale: Locale) -> RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = locale
        return formatter
    }
}

extension Date {
    @MainActor
    func relativeDescription(now: Date = .now) -> String {
        let seconds = abs(now.timeIntervalSince(self))
        if seconds < 15 {
            return L10n.string("just now")
        }
        return RelativeTimeFormatters.full(locale: L10n.locale).localizedString(for: self, relativeTo: now)
    }
}
