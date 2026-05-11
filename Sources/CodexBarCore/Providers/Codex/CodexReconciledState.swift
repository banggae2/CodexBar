import Foundation

public struct CodexReconciledState: Sendable {
    public let session: RateWindow?
    public let weekly: RateWindow?
    public let extraRateWindows: [NamedRateWindow]
    public let identity: ProviderIdentitySnapshot?
    public let updatedAt: Date

    public init(
        session: RateWindow?,
        weekly: RateWindow?,
        extraRateWindows: [NamedRateWindow] = [],
        identity: ProviderIdentitySnapshot?,
        updatedAt: Date)
    {
        self.session = session
        self.weekly = weekly
        self.extraRateWindows = extraRateWindows
        self.identity = identity
        self.updatedAt = updatedAt
    }

    public static func fromCLI(
        primary: RateWindow?,
        secondary: RateWindow?,
        extraRateWindows: [NamedRateWindow] = [],
        identity: ProviderIdentitySnapshot?,
        updatedAt: Date = Date()) -> CodexReconciledState?
    {
        self.make(
            primary: primary,
            secondary: secondary,
            extraRateWindows: extraRateWindows,
            identity: identity,
            updatedAt: updatedAt)
    }

    public static func fromOAuth(
        response: CodexUsageResponse,
        credentials: CodexOAuthCredentials,
        updatedAt: Date = Date()) -> CodexReconciledState?
    {
        self.make(
            primary: self.makeWindow(response.rateLimit?.primaryWindow),
            secondary: self.makeWindow(response.rateLimit?.secondaryWindow),
            extraRateWindows: self.extraRateWindows(from: response),
            identity: self.oauthIdentity(response: response, credentials: credentials),
            updatedAt: updatedAt)
    }

    public static func fromAttachedDashboard(
        snapshot: OpenAIDashboardSnapshot,
        provider: UsageProvider = .codex,
        accountEmail: String? = nil,
        accountPlan: String? = nil) -> CodexReconciledState?
    {
        let resolvedEmail = accountEmail ?? snapshot.signedInEmail
        let resolvedPlan = accountPlan ?? snapshot.accountPlan
        let identity = ProviderIdentitySnapshot(
            providerID: provider,
            accountEmail: resolvedEmail,
            accountOrganization: nil,
            loginMethod: resolvedPlan)

        return self.make(
            primary: snapshot.primaryLimit,
            secondary: snapshot.secondaryLimit,
            extraRateWindows: snapshot.extraRateWindows,
            identity: identity,
            updatedAt: snapshot.updatedAt)
    }

    public func toUsageSnapshot() -> UsageSnapshot {
        UsageSnapshot(
            primary: self.session,
            secondary: self.weekly,
            tertiary: nil,
            extraRateWindows: self.extraRateWindows.isEmpty ? nil : self.extraRateWindows,
            updatedAt: self.updatedAt,
            identity: self.identity)
    }

    public static func oauthIdentity(
        response: CodexUsageResponse,
        credentials: CodexOAuthCredentials) -> ProviderIdentitySnapshot
    {
        ProviderIdentitySnapshot(
            providerID: .codex,
            accountEmail: self.resolveAccountEmail(from: credentials),
            accountOrganization: nil,
            loginMethod: self.resolvePlan(response: response, credentials: credentials))
    }

    private static func make(
        primary: RateWindow?,
        secondary: RateWindow?,
        extraRateWindows: [NamedRateWindow],
        identity: ProviderIdentitySnapshot?,
        updatedAt: Date) -> CodexReconciledState?
    {
        let normalized = CodexRateWindowNormalizer.normalize(primary: primary, secondary: secondary)
        guard normalized.primary != nil || normalized.secondary != nil || !extraRateWindows.isEmpty else {
            return nil
        }

        return CodexReconciledState(
            session: normalized.primary,
            weekly: normalized.secondary,
            extraRateWindows: extraRateWindows,
            identity: identity,
            updatedAt: updatedAt)
    }

    static func extraRateWindows(from response: CodexUsageResponse) -> [NamedRateWindow] {
        var buckets: [(key: String, value: CodexUsageResponse.NamedRateLimitDetails)] = []
        if let keyedBuckets = response.rateLimitsByLimitId {
            buckets.append(contentsOf: keyedBuckets.keys.sorted().compactMap { key in
                keyedBuckets[key].map { (key, $0) }
            })
        }
        if let additionalBuckets = response.additionalRateLimits {
            buckets.append(contentsOf: additionalBuckets.enumerated().map { idx, bucket in
                let key = bucket.limitId?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? bucket.limitName?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? "additional-\(idx)"
                return (key, bucket)
            })
        }
        guard !buckets.isEmpty else { return [] }

        var seenIDs = Set<String>()
        return buckets.flatMap { key, bucket -> [NamedRateWindow] in
            guard key != "codex",
                  let limitName = UsageFetcher.normalizedCodexAccountField(bucket.limitName)
            else {
                return []
            }
            let idPrefix = Self.extraRateWindowIDPrefix(key: key, limitName: limitName)
            guard seenIDs.insert(idPrefix).inserted else { return [] }

            let normalized = CodexRateWindowNormalizer.normalize(
                primary: self.makeWindow(bucket.primaryWindow ?? bucket.limitSnapshot),
                secondary: self.makeWindow(bucket.secondaryWindow))
            return [
                normalized.primary.map { window in
                    NamedRateWindow(id: "\(idPrefix)-5h", title: "\(limitName) 5h", window: window)
                },
                normalized.secondary.map { window in
                    NamedRateWindow(id: "\(idPrefix)-weekly", title: "\(limitName) weekly", window: window)
                },
            ].compactMap(\.self)
        }
    }

    private static func extraRateWindowIDPrefix(key: String, limitName: String) -> String {
        let raw = key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? limitName : key
        let slug = raw
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return slug.isEmpty ? "codex-extra-limit" : slug
    }

    private static func makeWindow(_ window: CodexUsageResponse.WindowSnapshot?) -> RateWindow? {
        guard let window else { return nil }
        let resetDate = Date(timeIntervalSince1970: TimeInterval(window.resetAt))
        let resetDescription = UsageFormatter.resetDescription(from: resetDate)
        return RateWindow(
            usedPercent: Double(window.usedPercent),
            windowMinutes: window.limitWindowSeconds / 60,
            resetsAt: resetDate,
            resetDescription: resetDescription)
    }

    private static func resolveAccountEmail(from credentials: CodexOAuthCredentials) -> String? {
        guard let idToken = credentials.idToken,
              let payload = UsageFetcher.parseJWT(idToken)
        else {
            return nil
        }

        let profileDict = payload["https://api.openai.com/profile"] as? [String: Any]
        let email = (payload["email"] as? String) ?? (profileDict?["email"] as? String)
        return email?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func resolvePlan(response: CodexUsageResponse, credentials: CodexOAuthCredentials) -> String? {
        if let plan = response.planType?.rawValue, !plan.isEmpty { return plan }
        guard let idToken = credentials.idToken,
              let payload = UsageFetcher.parseJWT(idToken)
        else {
            return nil
        }

        let authDict = payload["https://api.openai.com/auth"] as? [String: Any]
        let plan = (authDict?["chatgpt_plan_type"] as? String) ?? (payload["chatgpt_plan_type"] as? String)
        return plan?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
