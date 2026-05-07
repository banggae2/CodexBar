import CodexBarCore
import Foundation
import Testing

struct ClaudePeakHoursTests {
    private static let eastern = TimeZone(identifier: "America/New_York")!

    private func date(
        year: Int = 2026,
        month: Int = 3,
        day: Int,
        hour: Int,
        minute: Int = 0,
        second: Int = 0) -> Date
    {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Self.eastern
        return cal.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second))!
    }

    @Test
    func `formerly peak weekday returns retired status`() {
        let status = ClaudePeakHours.status(at: self.date(day: 25, hour: 10))
        #expect(!status.isPeak)
        #expect(status.label == "Peak hours retired")
        #expect(status.minutesUntilTransition == 0)
    }

    @Test
    func `formerly off peak weekend returns retired status`() {
        let status = ClaudePeakHours.status(at: self.date(day: 28, hour: 10))
        #expect(!status.isPeak)
        #expect(status.label == "Peak hours retired")
        #expect(status.minutesUntilTransition == 0)
    }
}
