import SwiftUI

struct NotificationThresholdEditorState: Equatable {
    let thresholdNotificationsEnabled: Bool

    var canEditThresholds: Bool {
        true
    }
}

enum NotificationThresholdDisplayMode: Equatable {
    case used
    case remaining

    init(usageBarsShowUsed: Bool) {
        self = usageBarsShowUsed ? .used : .remaining
    }

    var isUsed: Bool {
        self == .used
    }

    var thresholdFormatKey: String {
        switch self {
        case .used:
            "Usage threshold format"
        case .remaining:
            "Remaining threshold format"
        }
    }

    func displayPercent(forStoredUsageThreshold threshold: Int) -> Int {
        switch self {
        case .used:
            threshold
        case .remaining:
            100 - threshold
        }
    }

    func storedUsageThreshold(forDisplayPercent percent: Int) -> Int {
        switch self {
        case .used:
            percent
        case .remaining:
            100 - percent
        }
    }
}

@MainActor
struct NotificationsPane: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 12) {
                    Text(L10n.string("Status monitoring"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    PreferenceToggleRow(
                        title: L10n.string("Check provider status"),
                        subtitle: L10n.string(
                            "Polls OpenAI/Claude status pages and Google Workspace for " +
                                "Gemini/Antigravity, surfacing incidents in the icon and menu."),
                        binding: self.$settings.statusChecksEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(L10n.string("App notifications"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    PreferenceToggleRow(
                        title: L10n.string("Login success notifications"),
                        subtitle: L10n.string(
                            "Send an alert when a provider login flow finishes successfully."),
                        binding: self.$settings.loginNotificationsEnabled)

                    PreferenceToggleRow(
                        title: L10n.string("Augment session expired"),
                        subtitle: L10n.string(
                            "Send an alert when Augment needs you to log in again."),
                        binding: self.$settings.augmentSessionExpiredNotificationsEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(L10n.string("5-hour limit alerts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    PreferenceToggleRow(
                        title: L10n.string(self.thresholdCopy.fiveHourToggleTitle),
                        subtitle: L10n.string(
                            self.thresholdCopy.fiveHourToggleSubtitle),
                        binding: self.$settings.sessionQuotaThresholdNotificationsEnabled)

                    QuotaThresholdEditor(
                        title: L10n.string(self.thresholdCopy.fiveHourEditorTitle),
                        caption: L10n.string("Each provider sends a threshold alert once per 5-hour window."),
                        displayMode: self.thresholdDisplayMode,
                        thresholds: self.$settings.sessionQuotaUsageThresholds)
                        .disabled(!self.sessionThresholdEditorState.canEditThresholds)

                    PreferenceToggleRow(
                        title: L10n.string("Notify when quota recovers"),
                        subtitle: L10n.string(
                            "Send an alert when a depleted five-hour session becomes available again."),
                        binding: self.$settings.sessionQuotaNotificationsEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(L10n.string("Weekly limit alerts"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    PreferenceToggleRow(
                        title: L10n.string(self.thresholdCopy.weeklyToggleTitle),
                        subtitle: L10n.string(
                            self.thresholdCopy.weeklyToggleSubtitle),
                        binding: self.$settings.weeklyLimitThresholdNotificationsEnabled)

                    QuotaThresholdEditor(
                        title: L10n.string(self.thresholdCopy.weeklyEditorTitle),
                        caption: L10n.string("Each provider sends a threshold alert once per weekly window."),
                        displayMode: self.thresholdDisplayMode,
                        thresholds: self.$settings.weeklyLimitUsageThresholds)
                        .disabled(!self.weeklyThresholdEditorState.canEditThresholds)

                    PreferenceToggleRow(
                        title: L10n.string("Notify when quota recovers"),
                        subtitle: L10n.string(
                            "Send an alert when a depleted weekly limit becomes available again."),
                        binding: self.$settings.weeklyLimitRecoveryNotificationsEnabled)

                    PreferenceToggleRow(
                        title: L10n.string("Weekly limit confetti"),
                        subtitle: L10n.string("Play full-screen confetti when weekly usage resets."),
                        binding: self.$settings.confettiOnWeeklyLimitResetsEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var sessionThresholdEditorState: NotificationThresholdEditorState {
        NotificationThresholdEditorState(
            thresholdNotificationsEnabled: self.settings.sessionQuotaThresholdNotificationsEnabled)
    }

    private var weeklyThresholdEditorState: NotificationThresholdEditorState {
        NotificationThresholdEditorState(
            thresholdNotificationsEnabled: self.settings.weeklyLimitThresholdNotificationsEnabled)
    }

    private var thresholdDisplayMode: NotificationThresholdDisplayMode {
        NotificationThresholdDisplayMode(usageBarsShowUsed: self.settings.usageBarsShowUsed)
    }

    private var thresholdCopy: ThresholdCopy {
        ThresholdCopy(displayMode: self.thresholdDisplayMode)
    }
}

private struct ThresholdCopy {
    let displayMode: NotificationThresholdDisplayMode

    var fiveHourToggleTitle: String {
        self.displayMode.isUsed ? "Notify at 5-hour usage thresholds" : "Notify at 5-hour remaining thresholds"
    }

    var fiveHourToggleSubtitle: String {
        self.displayMode.isUsed
            ? "Send an alert when five-hour session usage reaches selected percentages."
            : "Send an alert when five-hour session remaining quota reaches selected percentages."
    }

    var fiveHourEditorTitle: String {
        self.displayMode.isUsed ? "5-hour usage thresholds" : "5-hour remaining thresholds"
    }

    var weeklyToggleTitle: String {
        self.displayMode.isUsed ? "Notify at weekly usage thresholds" : "Notify at weekly remaining thresholds"
    }

    var weeklyToggleSubtitle: String {
        self.displayMode.isUsed
            ? "Send an alert when weekly usage reaches selected percentages."
            : "Send an alert when weekly remaining quota reaches selected percentages."
    }

    var weeklyEditorTitle: String {
        self.displayMode.isUsed ? "Weekly usage thresholds" : "Weekly remaining thresholds"
    }
}

@MainActor
private struct QuotaThresholdEditor: View {
    let title: String
    let caption: String
    let displayMode: NotificationThresholdDisplayMode
    @Binding var thresholds: [Int]
    @State private var thresholdText = ""

    private var pendingThreshold: Int? {
        guard let displayValue = Int(self.thresholdText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        guard self.isValidDisplayValue(displayValue) else { return nil }
        let storedValue = self.displayMode.storedUsageThreshold(forDisplayPercent: displayValue)
        guard !self.thresholds.contains(storedValue) else { return nil }
        return storedValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(self.title)
                .font(.body)
            Text(self.caption)
                .font(.footnote)
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(self.thresholds, id: \.self) { threshold in
                    HStack(spacing: 8) {
                        Text(L10n.string(
                            self.displayMode.thresholdFormatKey,
                            self.displayMode.displayPercent(forStoredUsageThreshold: threshold)))
                            .font(.body)
                        Spacer()
                        Button {
                            self.removeThreshold(threshold)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.string("Remove threshold"))
                    }
                }
            }

            HStack(spacing: 8) {
                TextField(L10n.string("Percent"), text: self.$thresholdText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)

                Button {
                    self.addThreshold()
                } label: {
                    Label(L10n.string("Add threshold"), systemImage: "plus")
                }
                .disabled(self.pendingThreshold == nil)
            }

            HStack(spacing: 8) {
                ForEach(SessionQuotaNotificationLogic.defaultUsageThresholds, id: \.self) { threshold in
                    Button(L10n.string(
                        "Percent format",
                        self.displayMode.displayPercent(forStoredUsageThreshold: threshold)))
                    {
                        self.addThreshold(threshold)
                    }
                    .controlSize(.small)
                    .disabled(self.thresholds.contains(threshold))
                }
            }
        }
    }

    private func addThreshold() {
        guard let value = self.pendingThreshold else { return }
        self.addThreshold(value)
        self.thresholdText = ""
    }

    private func addThreshold(_ value: Int) {
        self.thresholds.append(value)
    }

    private func removeThreshold(_ value: Int) {
        self.thresholds = self.thresholds.filter { $0 != value }
    }

    private func isValidDisplayValue(_ value: Int) -> Bool {
        switch self.displayMode {
        case .used:
            value > 0 && value <= 100
        case .remaining:
            value >= 0 && value < 100
        }
    }
}
