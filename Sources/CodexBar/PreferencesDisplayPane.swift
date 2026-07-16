import CodexBarCore
import SwiftUI

@MainActor
struct DisplayPane: View {
    private static let maxOverviewProviders = SettingsStore.mergedOverviewProviderLimit

    static func overviewProviderLimitText(limit: Int = Self.maxOverviewProviders) -> String {
        L("overview_choose_providers", String(limit))
    }

    @State private var isOverviewProviderPopoverPresented = false
    @State private var isCompactProviderPopoverPresented = false
    @Bindable var settings: SettingsStore
    @Bindable var store: UsageStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 12) {
                    Text(L("section_menu_bar"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: L("merge_icons_title"),
                        subtitle: L("merge_icons_subtitle"),
                        binding: self.$settings.mergeIcons)
                    PreferenceToggleRow(
                        title: L("switcher_shows_icons_title"),
                        subtitle: L("switcher_shows_icons_subtitle"),
                        binding: self.$settings.switcherShowsIcons)
                        .disabled(!self.settings.mergeIcons)
                        .opacity(self.settings.mergeIcons ? 1 : 0.5)
                    PreferenceToggleRow(
                        title: L("show_most_used_provider_title"),
                        subtitle: L("show_most_used_provider_subtitle"),
                        binding: self.$settings.menuBarShowsHighestUsage)
                        .disabled(!self.settings.mergeIcons)
                        .opacity(self.settings.mergeIcons ? 1 : 0.5)
                    PreferenceToggleRow(
                        title: L("menu_bar_shows_percent_title"),
                        subtitle: L("menu_bar_shows_percent_subtitle"),
                        binding: self.$settings.menuBarShowsBrandIconWithPercent)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Usage display style"))
                                .font(.body)
                            Text(L("Choose how usage appears in the menu bar."))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker(L("Usage display style"), selection: self.$settings.menuBarUsageDisplayStyle) {
                            ForEach(MenuBarUsageDisplayStyle.allCases) { style in
                                Text(style.label).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 220)
                    }
                    .disabled(!self.settings.menuBarShowsBrandIconWithPercent)
                    .opacity(self.settings.menuBarShowsBrandIconWithPercent ? 1 : 0.5)
                    self.compactProviderSelector
                        .disabled(!self.isCompactProviderSelectorEnabled)
                        .opacity(self.isCompactProviderSelectorEnabled ? 1 : 0.5)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("display_mode_title"))
                                .font(.body)
                            Text(L("display_mode_subtitle"))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker(L("Display mode"), selection: self.$settings.menuBarDisplayMode) {
                            ForEach(MenuBarDisplayMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 200)
                    }
                    .disabled(
                        !self.settings.menuBarShowsBrandIconWithPercent ||
                            self.settings.menuBarUsageDisplayStyle != .iconPercent)
                    .opacity(
                        self.settings.menuBarShowsBrandIconWithPercent &&
                            self.settings.menuBarUsageDisplayStyle == .iconPercent
                            ? 1
                            : 0.5)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text(L("section_menu_content"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: L("show_usage_as_used_title"),
                        subtitle: L("show_usage_as_used_subtitle"),
                        binding: self.$settings.usageBarsShowUsed)
                    PreferenceToggleRow(
                        title: L("show_quota_warning_markers_title"),
                        subtitle: L("show_quota_warning_markers_subtitle"),
                        binding: self.$settings.quotaWarningMarkersVisible)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("weekly_progress_work_days_title"))
                                .font(.body)
                            Text(L("weekly_progress_work_days_subtitle"))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker(L("weekly_progress_work_days_title"), selection: self.$settings.weeklyProgressWorkDays) {
                            Text(L("Off")).tag(nil as Int?)
                            Text(L("4 days")).tag(4 as Int?)
                            Text(L("5 days")).tag(5 as Int?)
                            Text(L("7 days")).tag(7 as Int?)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 100)
                    }
                    PreferenceToggleRow(
                        title: L("show_reset_time_as_clock_title"),
                        subtitle: L("show_reset_time_as_clock_subtitle"),
                        binding: self.$settings.resetTimesShowAbsolute)
                    PreferenceToggleRow(
                        title: L("show_provider_changelog_links_title"),
                        subtitle: L("show_provider_changelog_links_subtitle"),
                        binding: self.$settings.providerChangelogLinksEnabled)
                    PreferenceToggleRow(
                        title: L("show_credits_extra_usage_title"),
                        subtitle: L("show_credits_extra_usage_subtitle"),
                        binding: self.$settings.showOptionalCreditsAndExtraUsage)
                    PreferenceToggleRow(
                        title: L("show_all_token_accounts_title"),
                        subtitle: L("show_all_token_accounts_subtitle"),
                        binding: self.$settings.showAllTokenAccountsInMenu)
                    self.overviewProviderSelector
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .onAppear {
                self.reconcileOverviewSelection()
            }
            .onChange(of: self.settings.mergeIcons) { _, isEnabled in
                guard isEnabled else {
                    self.isOverviewProviderPopoverPresented = false
                    return
                }
                self.reconcileOverviewSelection()
            }
            .onChange(of: self.isCompactProviderSelectorEnabled) { _, isEnabled in
                if !isEnabled {
                    self.isCompactProviderPopoverPresented = false
                }
            }
            .onChange(of: self.activeProvidersInOrder) { _, _ in
                if self.activeProvidersInOrder.isEmpty {
                    self.isOverviewProviderPopoverPresented = false
                    self.isCompactProviderPopoverPresented = false
                }
                self.reconcileOverviewSelection()
            }
        }
    }

    private var compactProviderSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(L("Compact bar providers"))
                    .font(.body)
                Spacer(minLength: 0)
                if self.isCompactProviderSelectorEnabled {
                    Button(L("Configure…")) {
                        self.isCompactProviderPopoverPresented = true
                    }
                    .offset(y: 1)
                    .popover(isPresented: self.$isCompactProviderPopoverPresented, arrowEdge: .bottom) {
                        self.compactProviderPopover
                    }
                }
            }

            if !self.settings.menuBarShowsBrandIconWithPercent ||
                self.settings.menuBarUsageDisplayStyle != .compactBars
            {
                Text(L("Select Compact bars to choose which providers appear there."))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else if self.activeProvidersInOrder.isEmpty {
                Text(L("No enabled providers available for compact bars."))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else {
                Text(self.compactProviderSelectionSummary)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
    }

    private var compactProviderPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Show in compact bars"))
                .font(.headline)
            Text(L("Menu Bar Extra still shows every enabled provider."))
                .font(.footnote)
                .foregroundStyle(.tertiary)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(self.activeProvidersInOrder, id: \.self) { provider in
                        Toggle(
                            isOn: Binding(
                                get: { self.settings.isProviderShownInCompactBars(provider) },
                                set: { isShown in
                                    self.settings.setProviderShownInCompactBars(provider, isShown: isShown)
                                })) {
                            Text(self.providerDisplayName(provider))
                                .font(.body)
                        }
                        .toggleStyle(.checkbox)
                        .disabled(self.isLastCompactProvider(provider))
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .frame(width: 300)
    }

    private var overviewProviderSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(L("overview_tab_providers_title"))
                    .font(.body)
                Spacer(minLength: 0)
                if self.showsOverviewConfigureButton {
                    Button(L("configure")) {
                        self.isOverviewProviderPopoverPresented = true
                    }
                    .offset(y: 1)
                    .popover(isPresented: self.$isOverviewProviderPopoverPresented, arrowEdge: .bottom) {
                        self.overviewProviderPopover
                    }
                }
            }

            if !self.settings.mergeIcons {
                Text(L("overview_enable_merge_icons_hint"))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else if self.activeProvidersInOrder.isEmpty {
                Text(L("overview_no_providers_hint"))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            } else {
                Text(self.overviewProviderSelectionSummary)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
        }
    }

    private var overviewProviderPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Self.overviewProviderLimitText())
                .font(.headline)
            Text(L("overview_rows_follow_order"))
                .font(.footnote)
                .foregroundStyle(.tertiary)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(self.activeProvidersInOrder, id: \.self) { provider in
                        Toggle(
                            isOn: Binding(
                                get: { self.overviewSelectedProviders.contains(provider) },
                                set: { shouldSelect in
                                    self.setOverviewProviderSelection(provider: provider, isSelected: shouldSelect)
                                })) {
                            Text(self.providerDisplayName(provider))
                                .font(.body)
                        }
                        .toggleStyle(.checkbox)
                        .disabled(
                            !self.overviewSelectedProviders.contains(provider) &&
                                self.overviewSelectedProviders.count >= Self.maxOverviewProviders)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .frame(width: 280)
    }

    private var activeProvidersInOrder: [UsageProvider] {
        self.store.enabledProviders()
    }

    private var compactProviders: [UsageProvider] {
        self.settings.compactBarProviders(activeProviders: self.activeProvidersInOrder)
    }

    private var isCompactProviderSelectorEnabled: Bool {
        self.settings.menuBarShowsBrandIconWithPercent &&
            self.settings.menuBarUsageDisplayStyle == .compactBars &&
            !self.activeProvidersInOrder.isEmpty
    }

    private var compactProviderSelectionSummary: String {
        let selectedNames = self.compactProviders.map(self.providerDisplayName)
        guard !selectedNames.isEmpty else { return L("No providers selected") }
        return selectedNames.joined(separator: ", ")
    }

    private func isLastCompactProvider(_ provider: UsageProvider) -> Bool {
        self.settings.isProviderShownInCompactBars(provider) && self.compactProviders.count <= 1
    }

    private var overviewSelectedProviders: [UsageProvider] {
        self.settings.resolvedMergedOverviewProviders(
            activeProviders: self.activeProvidersInOrder,
            maxVisibleProviders: Self.maxOverviewProviders)
    }

    private var showsOverviewConfigureButton: Bool {
        self.settings.mergeIcons && !self.activeProvidersInOrder.isEmpty
    }

    private var overviewProviderSelectionSummary: String {
        let selectedNames = self.overviewSelectedProviders.map(self.providerDisplayName)
        guard !selectedNames.isEmpty else { return L("overview_no_providers_selected") }
        return selectedNames.joined(separator: ", ")
    }

    private func providerDisplayName(_ provider: UsageProvider) -> String {
        ProviderDescriptorRegistry.descriptor(for: provider).metadata.displayName
    }

    private func setOverviewProviderSelection(provider: UsageProvider, isSelected: Bool) {
        _ = self.settings.setMergedOverviewProviderSelection(
            provider: provider,
            isSelected: isSelected,
            activeProviders: self.activeProvidersInOrder,
            maxVisibleProviders: Self.maxOverviewProviders)
    }

    private func reconcileOverviewSelection() {
        _ = self.settings.reconcileMergedOverviewSelectedProviders(
            activeProviders: self.activeProvidersInOrder,
            maxVisibleProviders: Self.maxOverviewProviders)
    }
}
