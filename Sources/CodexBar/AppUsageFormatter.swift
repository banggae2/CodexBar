import CodexBarCore
import Foundation

enum AppUsageFormatter {
    static func usageLine(remaining: Double, used: Double, showUsed: Bool) -> String {
        let percent = showUsed ? used : remaining
        let clamped = min(100, max(0, percent))
        return showUsed
            ? L10n.string("Percent used format", clamped)
            : L10n.string("Percent left format", clamped)
    }

    static func resetCountdownDescription(from date: Date, now: Date = .init()) -> String {
        let seconds = max(0, date.timeIntervalSince(now))
        if seconds < 1 { return L10n.string("Duration now") }

        let totalMinutes = max(1, Int(ceil(seconds / 60.0)))
        return self.durationDescription(minutes: totalMinutes)
    }

    static func durationDescription(minutes totalMinutes: Int) -> String {
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        if days > 0 {
            if hours > 0 { return L10n.string("Duration in days hours format", days, hours) }
            return L10n.string("Duration in days format", days)
        }
        if hours > 0 {
            if minutes > 0 { return L10n.string("Duration in hours minutes format", hours, minutes) }
            return L10n.string("Duration in hours format", hours)
        }
        return L10n.string("Duration in minutes format", totalMinutes)
    }

    static func resetDescription(from date: Date, now: Date = .init()) -> String {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            return self.timeString(from: date)
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow)
        {
            return L10n.string("Tomorrow time format", self.timeString(from: date))
        }
        return self.dateTimeString(from: date)
    }

    static func resetLine(
        for window: RateWindow,
        style: ResetTimeDisplayStyle,
        now: Date = .init()) -> String?
    {
        if let date = window.resetsAt {
            let text = style == .countdown
                ? self.resetCountdownDescription(from: date, now: now)
                : self.resetDescription(from: date, now: now)
            return L10n.string("Resets format", text)
        }

        if let desc = window.resetDescription {
            let trimmed = desc.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return L10n.string("Resets format", self.stripEnglishResetPrefix(from: trimmed))
        }
        return nil
    }

    static func updatedString(from date: Date, now: Date = .init()) -> String {
        let delta = now.timeIntervalSince(date)
        if abs(delta) < 60 {
            return L10n.string("Updated just now")
        }
        if let hours = Calendar.current.dateComponents([.hour], from: date, to: now).hour, hours < 24 {
            let rel = RelativeDateTimeFormatter()
            rel.unitsStyle = .abbreviated
            rel.locale = L10n.locale
            return L10n.string("Updated relative format", rel.localizedString(for: date, relativeTo: now))
        }
        return L10n.string("Updated time format", self.timeString(from: date))
    }

    static func creditsString(from value: Double) -> String {
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.maximumFractionDigits = 2
        number.locale = L10n.locale
        let formatted = number.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return L10n.string("Credits left format", formatted)
    }

    static func creditEventSummary(_ event: CreditEvent) -> String {
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.maximumFractionDigits = 2
        number.locale = L10n.locale
        let credits = number.string(from: NSNumber(value: event.creditsUsed)) ?? "0"
        return L10n.string("Credit event summary format", self.dateString(from: event.date), event.service, credits)
    }

    private static func stripEnglishResetPrefix(from text: String) -> String {
        let lower = text.lowercased()
        if lower.hasPrefix("resets ") {
            return String(text.dropFirst("resets ".count))
        }
        if lower.hasPrefix("reset ") {
            return String(text.dropFirst("reset ".count))
        }
        return text
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func dateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = L10n.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
