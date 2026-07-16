# Upstream sync record — 2026-07-16

## Scope and safety

- Fork integration branch: `codex/sync-upstream-latest`
- Recoverable pre-merge commit: `0cd45eac`
- Backup branch: `codex/pre-upstream-sync-20260716`
- Previous upstream baseline: `da3b758f`
- Integrated upstream target: `2acf34cd`
- Upstream fetch URL: `https://github.com/steipete/CodexBar.git`
- Upstream push URL: `disabled://upstream`
- The original upstream repository is read-only for this integration. No upstream push or pull request is allowed.

## Resolution policy

1. Use the current upstream architecture, APIs, and file organization as the structural baseline.
2. Restore fork behavior by intent rather than copying obsolete implementations.
3. Preserve Korean localization, app-language-aware formatting, reset-time display preferences, and Codex named/additional quota presentation where the current upstream model still supports them.
4. Keep provider identity, plan, and quota data siloed by provider.
5. Prefer upstream tests and seams when an older fork test targets a removed implementation detail.

## Conflicts

### App, menu, and settings

| File | Conflict | Resolution status |
| --- | --- | --- |
| `Sources/CodexBar/CodexbarApp.swift` | content | Resolved — adopted upstream settings-pane routing and retained language reset behavior. |
| `Sources/CodexBar/MenuBarDisplayText.swift` | content | Resolved — retained localized duration/reset formatting on the upstream model. |
| `Sources/CodexBar/MenuCardView+ModelHelpers.swift` | content | Resolved — adopted upstream helpers and retained fork reset presentation. |
| `Sources/CodexBar/MenuCardView.swift` | content | Resolved — used upstream menu structure with fork presentation hooks. |
| `Sources/CodexBar/PreferencesComponents.swift` | content | Resolved — adopted upstream shared settings components. |
| `Sources/CodexBar/PreferencesDisplayPane.swift` | upstream deleted, fork modified | Resolved — removed obsolete pane and migrated fork options to `PreferencesMenuBarPane`. |
| `Sources/CodexBar/PreferencesGeneralPane.swift` | content | Resolved — adopted upstream pane split while preserving language controls. |
| `Sources/CodexBar/SettingsStore+Defaults.swift` | content | Resolved — combined upstream menu settings with fork usage-style defaults. |
| `Sources/CodexBar/SettingsStore.swift` | content | Resolved — combined upstream state loading with fork compact-bar state. |
| `Sources/CodexBar/SettingsStoreState.swift` | content | Resolved — retained both upstream and fork settings fields. |
| `Sources/CodexBar/StatusItemController+HostedSubmenus.swift` | content | Resolved — adopted upstream hosted-submenu lifecycle. |
| `Sources/CodexBar/StatusItemController+MenuActionMapping.swift` | content | Resolved — adopted upstream action mapping and retained localized output. |
| `Sources/CodexBar/StatusItemController.swift` | content | Resolved — adopted upstream lifecycle and restored compact display integration. |
| `Sources/CodexBar/UsageStore+Refresh.swift` | content | Resolved — adopted upstream refresh coordination with fork projection behavior. |

### Providers and core

| File | Conflict | Resolution status |
| --- | --- | --- |
| `Sources/CodexBar/Providers/Abacus/AbacusProviderImplementation.swift` | content | Resolved — adopted upstream shared cookie-source UI. |
| `Sources/CodexBar/Providers/Alibaba/AlibabaCodingPlanProviderImplementation.swift` | content | Resolved — adopted upstream shared cookie-source UI and token-plan structure. |
| `Sources/CodexBar/Providers/Codex/CodexConsumerProjection.swift` | content | Resolved — retained named/additional limits on the upstream projection model. |
| `Sources/CodexBar/Providers/Copilot/CopilotProviderImplementation.swift` | content | Resolved — combined upstream budget settings with localized fork strings. |
| `Sources/CodexBar/Providers/Cursor/CursorProviderImplementation.swift` | content | Resolved — adopted upstream shared cookie-source UI. |
| `Sources/CodexBar/Providers/Mistral/MistralProviderImplementation.swift` | content | Resolved — adopted upstream shared cookie-source UI. |
| `Sources/CodexBar/Providers/OpenCode/OpenCodeProviderUI.swift` | content | Resolved — adopted upstream shared cookie-source UI. |
| `Sources/CodexBarCore/Providers/Codex/CodexOAuth/CodexOAuthUsageFetcher.swift` | content | Resolved — combined upstream confidence/spend-control decoding with fork aliases and named limits. |
| `Sources/CodexBarCore/Providers/Zai/ZaiSettingsReader.swift` | content | Resolved — adopted upstream endpoint validation APIs. |
| `Sources/CodexBarCore/UsageFormatter.swift` | content | Resolved — retained app-locale-aware duration/reset formatting. |

### Localization and tests

| File | Conflict | Resolution status |
| --- | --- | --- |
| `Sources/CodexBar/Resources/ko.lproj/Localizable.strings` | add/add | Resolved — complete upstream catalog plus fork Korean strings; no duplicate keys or token mismatches. |
| `Tests/CodexBarTests/AlibabaTokenPlanProviderTests.swift` | content | Resolved — aligned with upstream provider architecture. |
| `Tests/CodexBarTests/CodexBackgroundRefreshCoalescingTests.swift` | content | Resolved — retained combined coalescing coverage; isolated suite passed. |
| `Tests/CodexBarTests/CodexOAuthTests.swift` | content | Resolved — covers upstream decoding confidence and fork named/additional limits. |
| `Tests/CodexBarTests/LocalizationLanguageCatalogTests.swift` | content | Resolved — retained Korean catalog and upstream language coverage. |
| `Tests/CodexBarTests/MenuCardModelCodexProjectionTests.swift` | content | Resolved — combined projection coverage. |
| `Tests/CodexBarTests/PathBuilderTests.swift` | content | Resolved — adopted upstream path behavior. |
| `Tests/CodexBarTests/StatusItemAnimationSignatureTests.swift` | content | Resolved — retained fork display signatures on upstream animation behavior. |
| `Tests/CodexBarTests/StatusItemControllerSplitLifecycleTests.swift` | content | Resolved — adopted upstream lifecycle seams. |
| `Tests/CodexBarTests/StatusMenuTokenAccountSwitcherTests.swift` | content | Resolved — retained account switching on upstream menu structure. |
| `Tests/CodexBarTests/UsageBreakdownChartMenuViewTests.swift` | add/add | Resolved — combined upstream chart coverage with fork usage-breakdown coverage. |
| `Tests/CodexBarTests/UsagePaceTextTests.swift` | content | Resolved — retained Korean pace and localized duration coverage. |

## Verification record

- Conflict-marker scan: passed; no unresolved markers or unmerged index entries.
- Build: the full project compiled successfully during `swift test`.
- Focused tests: `CodexBackgroundRefreshCoalescingTests` (22 tests), `StatusMenuSwitcherClickTests`
  (19 tests), `StatusItemControllerShutdownTests`, and the isolated AppKit test
  `open merged menu rebuilds switcher when usage bars mode changes` passed.
- Full `swift test --parallel --num-workers 1`: progressed without failures but was stopped after an AppKit menu
  test stalled; the stalled test passed immediately when rerun alone. No live provider or Keychain probes were run.
- `make check`: passed, including locale validation, SwiftFormat, and strict SwiftLint.
- Remote safety: upstream push URL remains `disabled://upstream`; no upstream or origin push was performed.
