import Testing
@testable import CodexBar

struct SessionQuotaNotificationLogicTests {
    @Test
    func `does nothing without previous value`() {
        let transition = SessionQuotaNotificationLogic.transition(previousRemaining: nil, currentRemaining: 0)
        #expect(transition == .none)
    }

    @Test
    func `detects depleted transition`() {
        let transition = SessionQuotaNotificationLogic.transition(previousRemaining: 12, currentRemaining: 0)
        #expect(transition == .depleted)
    }

    @Test
    func `detects restored transition`() {
        let transition = SessionQuotaNotificationLogic.transition(previousRemaining: 0, currentRemaining: 5)
        #expect(transition == .restored)
    }

    @Test
    func `ignores non transitions`() {
        #expect(SessionQuotaNotificationLogic.transition(previousRemaining: 0, currentRemaining: 0) == .none)
        #expect(SessionQuotaNotificationLogic.transition(previousRemaining: 10, currentRemaining: 10) == .none)
        #expect(SessionQuotaNotificationLogic.transition(previousRemaining: 10, currentRemaining: 9) == .none)
    }

    @Test
    func `treats tiny positive remaining as depleted`() {
        let transition = SessionQuotaNotificationLogic.transition(previousRemaining: 0, currentRemaining: 0.00001)
        #expect(transition == .none)
    }

    @Test
    func `detects crossed usage thresholds once`() {
        let crossed = SessionQuotaNotificationLogic.crossedUsageThresholds(
            previousUsed: 79,
            currentUsed: 91,
            thresholds: [80, 90],
            alreadySent: [])

        #expect(crossed == [80, 90])
    }

    @Test
    func `does not repeat already sent usage thresholds`() {
        let crossed = SessionQuotaNotificationLogic.crossedUsageThresholds(
            previousUsed: 79,
            currentUsed: 91,
            thresholds: [80, 90],
            alreadySent: [80])

        #expect(crossed == [90])
    }

    @Test
    func `normalizes usage thresholds`() {
        #expect(SessionQuotaNotificationLogic.normalizedUsageThresholds([90, 80, 80, 0, 120]) == [80, 90])
    }

    @Test
    func `default threshold presets include quarter steps`() {
        #expect(SessionQuotaNotificationLogic.defaultUsageThresholds == [25, 50, 75, 100])
    }

    @Test
    func `threshold editor remains editable when threshold alerts are off`() {
        let state = NotificationThresholdEditorState(thresholdNotificationsEnabled: false)
        #expect(state.canEditThresholds)
    }

    @Test
    func `threshold display mode uses stored usage values when showing used`() {
        let mode = NotificationThresholdDisplayMode(usageBarsShowUsed: true)

        #expect(mode.displayPercent(forStoredUsageThreshold: 80) == 80)
        #expect(mode.storedUsageThreshold(forDisplayPercent: 80) == 80)
    }

    @Test
    func `threshold display mode inverts stored usage values when showing remaining`() {
        let mode = NotificationThresholdDisplayMode(usageBarsShowUsed: false)

        #expect(mode.displayPercent(forStoredUsageThreshold: 80) == 20)
        #expect(mode.storedUsageThreshold(forDisplayPercent: 20) == 80)
        #expect(mode.storedUsageThreshold(forDisplayPercent: 0) == 100)
    }
}
