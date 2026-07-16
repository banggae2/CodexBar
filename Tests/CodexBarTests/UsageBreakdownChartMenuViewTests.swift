import Testing
@testable import CodexBar

struct UsageBreakdownChartMenuViewTests {
    @Test
    @MainActor
    func `service legend restores recognizable service icons`() {
        #expect(UsageBreakdownChartMenuView.iconName(for: "CLI") == "terminal")
        #expect(UsageBreakdownChartMenuView.iconName(for: "Desktop") == "macwindow")
        #expect(UsageBreakdownChartMenuView.iconName(for: "GitHub Review") == "checkmark.seal")
        #expect(UsageBreakdownChartMenuView.iconName(for: "skillusage:imagegen") == "sparkles")
        #expect(UsageBreakdownChartMenuView.iconName(for: "Imagegen") == "sparkles")
    }

    @Test
    @MainActor
    func `unknown service keeps a stable fallback icon`() {
        #expect(UsageBreakdownChartMenuView.iconName(for: "unknown-service") == "square.grid.2x2")
    }
}
