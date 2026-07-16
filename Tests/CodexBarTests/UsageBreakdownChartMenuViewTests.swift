import Testing
@testable import CodexBar

@Suite("Usage breakdown chart menu")
@MainActor
struct UsageBreakdownChartMenuViewTests {
    @Test
    func `service legend restores recognizable service icons`() {
        #expect(UsageBreakdownChartMenuView.iconName(for: "CLI") == "terminal")
        #expect(UsageBreakdownChartMenuView.iconName(for: "Desktop") == "macwindow")
        #expect(UsageBreakdownChartMenuView.iconName(for: "GitHub Review") == "checkmark.seal")
        #expect(UsageBreakdownChartMenuView.iconName(for: "skillusage:imagegen") == "sparkles")
        #expect(UsageBreakdownChartMenuView.iconName(for: "Imagegen") == "sparkles")
    }

    @Test
    func `unknown service keeps a stable fallback icon`() {
        #expect(UsageBreakdownChartMenuView.iconName(for: "unknown-service") == "square.grid.2x2")
    }

    @Test
    func `valid totals remain visible when service rows are absent`() {
        #expect(
            UsageBreakdownChartMenuView.presentationState(
                hasSummary: true,
                hasChartPoints: false) == .totalsOnly)
    }

    @Test
    func `service rows select the chart presentation`() {
        #expect(
            UsageBreakdownChartMenuView.presentationState(
                hasSummary: true,
                hasChartPoints: true) == .chart)
    }

    @Test
    func `missing totals and service rows select the empty presentation`() {
        #expect(
            UsageBreakdownChartMenuView.presentationState(
                hasSummary: false,
                hasChartPoints: false) == .empty)
    }
}
