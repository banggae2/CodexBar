import CodexBarMacroSupport
import Foundation

@ProviderDescriptorRegistration
@ProviderDescriptorDefinition
public enum ClaudeProviderDescriptor {
    static func makeDescriptor() -> ProviderDescriptor {
        ProviderDescriptor(
            id: .claude,
            metadata: ProviderMetadata(
                id: .claude,
                displayName: "Claude",
                sessionLabel: "Session",
                weeklyLabel: "Weekly",
                opusLabel: "Sonnet",
                supportsOpus: true,
                supportsCredits: false,
                creditsHint: "",
                toggleTitle: "Show Claude Code usage",
                cliName: "claude",
                defaultEnabled: false,
                isPrimaryProvider: true,
                usesAccountFallback: false,
                browserCookieOrder: ProviderBrowserCookieDefaults.defaultImportOrder,
                dashboardURL: "https://console.anthropic.com/settings/billing",
                subscriptionDashboardURL: "https://claude.ai/settings/usage",
                statusPageURL: "https://status.claude.com/"),
            branding: ProviderBranding(
                iconStyle: .claude,
                iconResourceName: "ProviderIcon-claude",
                color: ProviderColor(red: 204 / 255, green: 124 / 255, blue: 94 / 255)),
            tokenCost: ProviderTokenCostConfig(
                supportsTokenCost: true,
                noDataMessage: self.noDataMessage),
            fetchPlan: ProviderFetchPlan(
                sourceModes: [.auto, .cli, .claudeDashboardPlugin, .log, .oauth, .api],
                pipeline: ProviderFetchPipeline(resolveStrategies: self.resolveStrategies)),
            cli: ProviderCLIConfig(
                name: "claude",
                versionDetector: { browserDetection in
                    ClaudeUsageFetcher(browserDetection: browserDetection).detectVersion()
                }))
    }

    private static func resolveStrategies(context: ProviderFetchContext) async -> [any ProviderFetchStrategy] {
        let planningInput = await Self.makePlanningInput(context: context)
        let plan = ClaudeSourcePlanner.resolve(input: planningInput)

        return plan.orderedSteps.map { step in
            let strategy: any ProviderFetchStrategy = switch step.dataSource {
            case .cli:
                ClaudeCLIFetchStrategy(
                    useWebExtras: false,
                    manualCookieHeader: nil,
                    browserDetection: context.browserDetection)
            case .claudeDashboardPlugin:
                ClaudeDashboardPluginCacheFetchStrategy()
            case .log:
                ClaudeLocalLogFetchStrategy()
            case .oauth:
                ClaudeOAuthFetchStrategy()
            case .web:
                ClaudeWebFetchStrategy(browserDetection: context.browserDetection)
            case .auto:
                fatalError("Planner must not emit .auto as an executable step.")
            }
            return ClaudePlannedFetchStrategy(base: strategy, plannedStep: step)
        }
    }

    private static func makePlanningInput(context: ProviderFetchContext) async -> ClaudeSourcePlanningInput {
        let webExtrasEnabled = context.settings?.claude?.webExtrasEnabled ?? false
        let needsOAuthAvailability = context.sourceMode == .auto ||
            context.sourceMode == .oauth ||
            context.sourceMode == .api

        return ClaudeSourcePlanningInput(
            runtime: context.runtime,
            selectedDataSource: Self.sourceDataSource(from: context.sourceMode),
            webExtrasEnabled: webExtrasEnabled,
            hasWebSession: false,
            hasCLI: ClaudeCLIResolver.isAvailable(environment: context.env),
            hasDashboardPluginCache: ClaudeDashboardPluginCacheFetchStrategy.hasCache(),
            hasOAuthCredentials: needsOAuthAvailability && ClaudeOAuthPlanningAvailability.isAvailable(
                runtime: context.runtime,
                sourceMode: context.sourceMode,
                environment: context.env))
    }

    fileprivate static func noDataMessage() -> String {
        "No Claude usage logs found in ~/.config/claude/projects or ~/.claude/projects."
    }

    public static func resolveUsageStrategy(
        selectedDataSource: ClaudeUsageDataSource,
        webExtrasEnabled: Bool,
        hasWebSession: Bool,
        hasCLI: Bool,
        hasOAuthCredentials: Bool) -> ClaudeUsageStrategy
    {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: selectedDataSource,
            webExtrasEnabled: webExtrasEnabled,
            hasWebSession: hasWebSession,
            hasCLI: hasCLI,
            hasLocalLogs: true,
            hasOAuthCredentials: hasOAuthCredentials))
        return plan.compatibilityStrategy ?? ClaudeUsageStrategy(dataSource: selectedDataSource, useWebExtras: false)
    }

    private static func sourceDataSource(from mode: ProviderSourceMode) -> ClaudeUsageDataSource {
        switch mode {
        case .auto:
            .auto
        case .web:
            .auto
        case .cli:
            .cli
        case .claudeDashboardPlugin:
            .claudeDashboardPlugin
        case .log:
            .log
        case .oauth, .api:
            .oauth
        }
    }
}

public struct ClaudeUsageStrategy: Equatable, Sendable {
    public let dataSource: ClaudeUsageDataSource
    public let useWebExtras: Bool
}

public enum ClaudeOAuthPlanningAvailability {
    public static func isAvailable(
        runtime: ProviderRuntime,
        sourceMode: ProviderSourceMode,
        environment: [String: String]) -> Bool
    {
        ClaudeOAuthFetchStrategy.isPlausiblyAvailable(
            runtime: runtime,
            sourceMode: sourceMode,
            environment: environment)
    }
}

private struct ClaudePlannedFetchStrategy: ProviderFetchStrategy {
    let base: any ProviderFetchStrategy
    let plannedStep: ClaudeFetchPlanStep

    var id: String {
        self.base.id
    }

    var kind: ProviderFetchKind {
        self.base.kind
    }

    func isAvailable(_ context: ProviderFetchContext) async -> Bool {
        if context.sourceMode == .auto {
            return self.plannedStep.isPlausiblyAvailable
        }
        return await self.base.isAvailable(context)
    }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        try await self.base.fetch(context)
    }

    func shouldFallback(on error: Error, context: ProviderFetchContext) -> Bool {
        self.base.shouldFallback(on: error, context: context)
    }
}

struct ClaudeOAuthFetchStrategy: ProviderFetchStrategy {
    let id: String = "claude.oauth"
    let kind: ProviderFetchKind = .oauth

    #if DEBUG
    @TaskLocal static var nonInteractiveCredentialRecordOverride: ClaudeOAuthCredentialRecord?
    @TaskLocal static var claudeCLIAvailableOverride: Bool?
    #endif

    private func loadNonInteractiveCredentialRecord(environment: [String: String]) -> ClaudeOAuthCredentialRecord? {
        #if DEBUG
        if let override = Self.nonInteractiveCredentialRecordOverride { return override }
        #endif

        return try? ClaudeOAuthCredentialsStore.loadRecord(
            environment: environment,
            allowKeychainPrompt: false,
            respectKeychainPromptCooldown: true,
            allowClaudeKeychainRepairWithoutPrompt: false)
    }

    private func isClaudeCLIAvailable(environment: [String: String]) -> Bool {
        #if DEBUG
        if let override = Self.claudeCLIAvailableOverride { return override }
        #endif
        return ClaudeCLIResolver.isAvailable(environment: environment)
    }

    static func isPlausiblyAvailable(
        runtime: ProviderRuntime,
        sourceMode: ProviderSourceMode,
        environment: [String: String]) -> Bool
    {
        let hasEnvironmentOAuthToken = !(environment[ClaudeOAuthCredentialsStore.environmentTokenKey]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
        if hasEnvironmentOAuthToken {
            return true
        }

        let strategy = ClaudeOAuthFetchStrategy()
        let nonInteractiveRecord = strategy.loadNonInteractiveCredentialRecord(environment: environment)
        let nonInteractiveCredentials = nonInteractiveRecord?.credentials
        let hasRequiredScopeWithoutPrompt = nonInteractiveCredentials?.scopes.contains("user:profile") == true
        if hasRequiredScopeWithoutPrompt, nonInteractiveCredentials?.isExpired == false {
            return true
        }

        let claudeCLIAvailable = strategy.isClaudeCLIAvailable(environment: environment)

        if let nonInteractiveRecord, hasRequiredScopeWithoutPrompt, nonInteractiveRecord.credentials.isExpired {
            switch nonInteractiveRecord.owner {
            case .codexbar:
                let refreshToken = nonInteractiveRecord.credentials.refreshToken?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if sourceMode == .auto {
                    return !refreshToken.isEmpty
                }
                return true
            case .claudeCLI:
                if sourceMode == .auto {
                    return claudeCLIAvailable
                }
                return true
            case .environment:
                return sourceMode != .auto
            }
        }

        guard sourceMode == .auto else { return true }

        let fallbackPromptMode = ClaudeOAuthKeychainPromptPreference.securityFrameworkFallbackMode()
        let promptPolicyApplicable = ClaudeOAuthKeychainPromptPreference.isApplicable()
        if ProviderInteractionContext.current == .userInitiated {
            _ = ClaudeOAuthKeychainAccessGate.clearDenied()
        }

        let shouldAllowStartupBootstrap = runtime == .app &&
            ProviderRefreshContext.current == .startup &&
            ProviderInteractionContext.current == .background &&
            fallbackPromptMode == .onlyOnUserAction &&
            !ClaudeOAuthCredentialsStore.hasCachedCredentials(environment: environment)
        if shouldAllowStartupBootstrap {
            return ClaudeOAuthKeychainAccessGate.shouldAllowPrompt()
        }

        if promptPolicyApplicable,
           !ClaudeOAuthKeychainAccessGate.shouldAllowPrompt()
        {
            return false
        }
        return ClaudeOAuthCredentialsStore.hasClaudeKeychainCredentialsWithoutPrompt()
    }

    func isAvailable(_ context: ProviderFetchContext) async -> Bool {
        Self.isPlausiblyAvailable(
            runtime: context.runtime,
            sourceMode: context.sourceMode,
            environment: context.env)
    }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        let fetcher = ClaudeUsageFetcher(
            browserDetection: context.browserDetection,
            environment: context.env,
            dataSource: .oauth,
            oauthKeychainPromptCooldownEnabled: context.sourceMode == .auto,
            allowBackgroundDelegatedRefresh: context.runtime == .cli,
            allowStartupBootstrapPrompt: context.runtime == .app &&
                (context.sourceMode == .auto || context.sourceMode == .oauth || context.sourceMode == .api),
            useWebExtras: false)
        let usage = try await fetcher.loadLatestUsage(model: "sonnet")
        return self.makeResult(
            usage: Self.snapshot(from: usage),
            sourceLabel: "oauth")
    }

    func shouldFallback(on _: Error, context: ProviderFetchContext) -> Bool {
        // In Auto mode, fall back to the next strategy (cli/web) if OAuth fails (e.g. user cancels keychain prompt
        // or auth breaks).
        context.runtime == .app && context.sourceMode == .auto
    }

    fileprivate static func snapshot(from usage: ClaudeUsageSnapshot) -> UsageSnapshot {
        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: usage.accountEmail,
            accountOrganization: usage.accountOrganization,
            loginMethod: usage.loginMethod)
        return UsageSnapshot(
            primary: usage.primary,
            secondary: usage.secondary,
            tertiary: usage.opus,
            extraRateWindows: usage.extraRateWindows.isEmpty ? nil : usage.extraRateWindows,
            providerCost: usage.providerCost,
            updatedAt: usage.updatedAt,
            identity: identity)
    }
}

struct ClaudeWebFetchStrategy: ProviderFetchStrategy {
    let id: String = "claude.web"
    let kind: ProviderFetchKind = .web
    let browserDetection: BrowserDetection

    func isAvailable(_ context: ProviderFetchContext) async -> Bool {
        Self.isAvailableForFallback(context: context, browserDetection: self.browserDetection)
    }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        let fetcher = ClaudeUsageFetcher(
            browserDetection: browserDetection,
            dataSource: .web,
            useWebExtras: false,
            manualCookieHeader: Self.manualCookieHeader(from: context))
        let usage = try await fetcher.loadLatestUsage(model: "sonnet")
        return self.makeResult(
            usage: ClaudeOAuthFetchStrategy.snapshot(from: usage),
            sourceLabel: "web")
    }

    func shouldFallback(on error: Error, context: ProviderFetchContext) -> Bool {
        guard context.sourceMode == .auto else { return false }
        _ = error
        // In CLI runtime auto mode, web comes before CLI so fallback is required.
        // In app runtime auto mode, web is terminal and should surface its concrete error.
        return context.runtime == .cli
    }

    fileprivate static func isAvailableForFallback(
        context: ProviderFetchContext,
        browserDetection: BrowserDetection) -> Bool
    {
        if let header = self.manualCookieHeader(from: context) {
            return ClaudeWebAPIFetcher.hasSessionKey(cookieHeader: header)
        }
        guard context.settings?.claude?.cookieSource != .off else { return false }
        return ClaudeWebAPIFetcher.hasSessionKey(browserDetection: browserDetection)
    }

    private static func manualCookieHeader(from context: ProviderFetchContext) -> String? {
        guard context.settings?.claude?.cookieSource == .manual else { return nil }
        return CookieHeaderNormalizer.normalize(context.settings?.claude?.manualCookieHeader)
    }
}

struct ClaudeCLIFetchStrategy: ProviderFetchStrategy {
    let id: String = "claude.cli"
    let kind: ProviderFetchKind = .cli
    let useWebExtras: Bool
    let manualCookieHeader: String?
    let browserDetection: BrowserDetection

    func isAvailable(_: ProviderFetchContext) async -> Bool {
        true
    }

    func fetch(_ context: ProviderFetchContext) async throws -> ProviderFetchResult {
        let keepAlive = context.settings?.debugKeepCLISessionsAlive ?? false
        let fetcher = ClaudeUsageFetcher(
            browserDetection: browserDetection,
            environment: context.env,
            dataSource: .cli,
            useWebExtras: self.useWebExtras,
            manualCookieHeader: self.manualCookieHeader,
            keepCLISessionsAlive: keepAlive)
        let usage = try await fetcher.loadLatestUsage(model: "sonnet")
        return self.makeResult(
            usage: ClaudeOAuthFetchStrategy.snapshot(from: usage),
            sourceLabel: "claude")
    }

    func shouldFallback(on _: Error, context: ProviderFetchContext) -> Bool {
        _ = context
        return false
    }
}

struct ClaudeDashboardPluginCacheFetchStrategy: ProviderFetchStrategy {
    let id: String = "claude.dashboard-plugin"
    let kind: ProviderFetchKind = .localProbe
    let cacheDirectory: URL

    init(cacheDirectory: URL = Self.defaultCacheDirectory()) {
        self.cacheDirectory = cacheDirectory
    }

    static func defaultCacheDirectory(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL
    {
        homeDirectory
            .appendingPathComponent(".cache", isDirectory: true)
            .appendingPathComponent("claude-dashboard", isDirectory: true)
    }

    static func hasCache() -> Bool {
        self.latestCacheFile(in: self.defaultCacheDirectory()) != nil
    }

    func isAvailable(_: ProviderFetchContext) async -> Bool {
        Self.latestCacheFile(in: self.cacheDirectory) != nil
    }

    func fetch(_: ProviderFetchContext) async throws -> ProviderFetchResult {
        guard let cacheFile = Self.latestCacheFile(in: self.cacheDirectory) else {
            throw ClaudeUsageError.parseFailed("No Claude Dashboard Plugin cache found in ~/.cache/claude-dashboard.")
        }

        let data = try Data(contentsOf: cacheFile)
        let updatedAt = (try? FileManager.default.attributesOfItem(atPath: cacheFile.path)[.modificationDate] as? Date)
            ?? Date()
        let usage = try Self.parseUsageSnapshot(from: data, updatedAt: updatedAt)
        return self.makeResult(usage: usage, sourceLabel: "claude-dashboard-plugin")
    }

    func shouldFallback(on _: Error, context: ProviderFetchContext) -> Bool {
        context.sourceMode == .auto
    }

    private static func latestCacheFile(in directory: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants])
        else {
            return nil
        }

        var newest: (url: URL, modifiedAt: Date)?
        for case let url as URL in enumerator {
            guard url.pathExtension == "json",
                  url.lastPathComponent.hasPrefix("cache-")
            else {
                continue
            }

            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey])
            guard values?.isRegularFile == true,
                  let modifiedAt = values?.contentModificationDate
            else {
                continue
            }

            if newest == nil || modifiedAt > newest!.modifiedAt {
                newest = (url, modifiedAt)
            }
        }
        return newest?.url
    }

    private static func parseUsageSnapshot(from data: Data, updatedAt: Date) throws -> UsageSnapshot {
        let envelope = try JSONDecoder().decode(ClaudeDashboardPluginCacheEnvelope.self, from: data)

        func makeWindow(_ bucket: ClaudeDashboardPluginCacheBucket?, windowMinutes: Int) -> RateWindow? {
            guard let utilization = bucket?.utilization else { return nil }
            let resetsAt = ClaudeOAuthUsageFetcher.parseISO8601Date(bucket?.resetsAt)
            return RateWindow(
                usedPercent: utilization,
                windowMinutes: windowMinutes,
                resetsAt: resetsAt,
                resetDescription: nil)
        }

        let primary = makeWindow(envelope.data?.fiveHour ?? envelope.fiveHour, windowMinutes: 5 * 60)
        let secondary = makeWindow(envelope.data?.sevenDay ?? envelope.sevenDay, windowMinutes: 7 * 24 * 60)
        let tertiary = makeWindow(
            envelope.data?.sevenDaySonnet
                ?? envelope.sevenDaySonnet
                ?? envelope.data?.sevenDayOpus
                ?? envelope.sevenDayOpus,
            windowMinutes: 7 * 24 * 60)
        guard primary != nil || secondary != nil || tertiary != nil else {
            throw ClaudeUsageError.parseFailed("Claude Dashboard Plugin cache did not include usage limits.")
        }

        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: "Claude Dashboard Plugin")
        return UsageSnapshot(
            primary: primary,
            secondary: secondary,
            tertiary: tertiary,
            updatedAt: updatedAt,
            identity: identity)
    }
}

private struct ClaudeDashboardPluginCacheEnvelope: Decodable {
    let data: ClaudeDashboardPluginCachePayload?
    let fiveHour: ClaudeDashboardPluginCacheBucket?
    let sevenDay: ClaudeDashboardPluginCacheBucket?
    let sevenDaySonnet: ClaudeDashboardPluginCacheBucket?
    let sevenDayOpus: ClaudeDashboardPluginCacheBucket?

    enum CodingKeys: String, CodingKey {
        case data
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
    }
}

private struct ClaudeDashboardPluginCachePayload: Decodable {
    let fiveHour: ClaudeDashboardPluginCacheBucket?
    let sevenDay: ClaudeDashboardPluginCacheBucket?
    let sevenDaySonnet: ClaudeDashboardPluginCacheBucket?
    let sevenDayOpus: ClaudeDashboardPluginCacheBucket?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
        case sevenDayOpus = "seven_day_opus"
    }
}

private struct ClaudeDashboardPluginCacheBucket: Decodable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct ClaudeLocalLogFetchStrategy: ProviderFetchStrategy {
    let id: String = "claude.log"
    let kind: ProviderFetchKind = .localProbe

    func isAvailable(_: ProviderFetchContext) async -> Bool {
        true
    }

    func fetch(_: ProviderFetchContext) async throws -> ProviderFetchResult {
        let tokenSnapshot = try await CostUsageFetcher().loadTokenSnapshot(
            provider: .claude,
            forceRefresh: true)
        guard !tokenSnapshot.daily.isEmpty else {
            throw ClaudeUsageError.parseFailed(ClaudeProviderDescriptor.noDataMessage())
        }

        let identity = ProviderIdentitySnapshot(
            providerID: .claude,
            accountEmail: nil,
            accountOrganization: nil,
            loginMethod: "Local logs")
        let usage = UsageSnapshot(
            primary: nil,
            secondary: nil,
            updatedAt: tokenSnapshot.updatedAt,
            identity: identity)
        return self.makeResult(usage: usage, sourceLabel: "log")
    }

    func shouldFallback(on _: Error, context: ProviderFetchContext) -> Bool {
        context.sourceMode == .auto
    }
}
