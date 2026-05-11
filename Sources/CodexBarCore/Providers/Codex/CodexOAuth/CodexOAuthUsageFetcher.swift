import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct CodexUsageResponse: Decodable, Sendable {
    public let planType: PlanType?
    public let rateLimit: RateLimitDetails?
    public let rateLimitsByLimitId: [String: NamedRateLimitDetails]?
    public let additionalRateLimits: [NamedRateLimitDetails]?
    public let credits: CreditDetails?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case planTypeCamel = "planType"
        case rateLimit = "rate_limit"
        case rateLimitCamel = "rateLimit"
        case rateLimits
        case rateLimitsByLimitId = "rate_limits_by_limit_id"
        case rateLimitsByLimitIdCamel = "rateLimitsByLimitId"
        case additionalRateLimits = "additional_rate_limits"
        case additionalRateLimitsCamel = "additionalRateLimits"
        case credits
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.planType = Self.decodeFirst(PlanType.self, from: container, keys: [.planType, .planTypeCamel])
        self.rateLimit = Self.decodeFirst(
            RateLimitDetails.self,
            from: container,
            keys: [.rateLimit, .rateLimitCamel, .rateLimits])
        self.rateLimitsByLimitId = Self.decodeFirst(
            [String: NamedRateLimitDetails].self,
            from: container,
            keys: [.rateLimitsByLimitId, .rateLimitsByLimitIdCamel])
        self.additionalRateLimits = Self.decodeFirstRateLimitCollection(
            from: container,
            keys: [.additionalRateLimits, .additionalRateLimitsCamel])
        self.credits = Self.decodeFirst(CreditDetails.self, from: container, keys: [.credits])
    }

    private static func decodeFirst<T: Decodable>(
        _ type: T.Type,
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]) -> T?
    {
        for key in keys {
            if let value = try? container.decodeIfPresent(type, forKey: key) {
                return value
            }
        }
        return nil
    }

    private static func decodeFirstRateLimitCollection(
        from container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]) -> [NamedRateLimitDetails]?
    {
        for key in keys {
            if let value = try? container.decodeIfPresent([NamedRateLimitDetails].self, forKey: key) {
                return value
            }
            if let value = try? container.decodeIfPresent([String: NamedRateLimitDetails].self, forKey: key) {
                return value.keys.sorted().compactMap { value[$0] }
            }
        }
        return nil
    }

    public enum PlanType: Sendable, Decodable, Equatable {
        case guest
        case free
        case go
        case plus
        case pro
        case freeWorkspace
        case team
        case business
        case education
        case quorum
        case k12
        case enterprise
        case edu
        case unknown(String)

        public var rawValue: String {
            switch self {
            case .guest: "guest"
            case .free: "free"
            case .go: "go"
            case .plus: "plus"
            case .pro: "pro"
            case .freeWorkspace: "free_workspace"
            case .team: "team"
            case .business: "business"
            case .education: "education"
            case .quorum: "quorum"
            case .k12: "k12"
            case .enterprise: "enterprise"
            case .edu: "edu"
            case let .unknown(value): value
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            switch value {
            case "guest": self = .guest
            case "free": self = .free
            case "go": self = .go
            case "plus": self = .plus
            case "pro": self = .pro
            case "free_workspace": self = .freeWorkspace
            case "team": self = .team
            case "business": self = .business
            case "education": self = .education
            case "quorum": self = .quorum
            case "k12": self = .k12
            case "enterprise": self = .enterprise
            case "edu": self = .edu
            default:
                self = .unknown(value)
            }
        }
    }

    public struct RateLimitDetails: Decodable, Sendable {
        public let primaryWindow: WindowSnapshot?
        public let secondaryWindow: WindowSnapshot?
        let primaryWindowDecodeFailed: Bool
        let secondaryWindowDecodeFailed: Bool

        enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case primaryWindowCamel = "primaryWindow"
            case primary
            case secondaryWindow = "secondary_window"
            case secondaryWindowCamel = "secondaryWindow"
            case secondary
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let primaryKeys: [CodingKeys] = [.primaryWindow, .primaryWindowCamel, .primary]
            let secondaryKeys: [CodingKeys] = [.secondaryWindow, .secondaryWindowCamel, .secondary]
            let primary = Self.decodeWindow(container: container, keys: primaryKeys)
            self.primaryWindow = primary.window
            self.primaryWindowDecodeFailed = primary.decodeFailed

            let secondary = Self.decodeWindow(container: container, keys: secondaryKeys)
            self.secondaryWindow = secondary.window
            self.secondaryWindowDecodeFailed = secondary.decodeFailed
        }

        private static func decodeWindow(
            container: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]) -> (window: WindowSnapshot?, decodeFailed: Bool)
        {
            var hadValue = false
            for key in keys {
                hadValue = hadValue || Self.hasNonNilValue(container: container, key: key)
                do {
                    if let value = try container.decodeIfPresent(WindowSnapshot.self, forKey: key) {
                        return (value, false)
                    }
                } catch {
                    return (nil, hadValue)
                }
            }
            return (nil, hadValue)
        }

        private static func hasNonNilValue(
            container: KeyedDecodingContainer<CodingKeys>,
            key: CodingKeys) -> Bool
        {
            guard container.contains(key) else { return false }
            return (try? container.decodeNil(forKey: key)) == false
        }

        var hasWindowDecodeFailure: Bool {
            self.primaryWindowDecodeFailed || self.secondaryWindowDecodeFailed
        }
    }

    public struct NamedRateLimitDetails: Decodable, Sendable {
        public let limitId: String?
        public let limitName: String?
        public let primaryWindow: WindowSnapshot?
        public let secondaryWindow: WindowSnapshot?
        public let limitSnapshot: WindowSnapshot?

        enum CodingKeys: String, CodingKey {
            case limitId = "limit_id"
            case limitIdCamel = "limitId"
            case meteredFeature = "metered_feature"
            case meteredFeatureCamel = "meteredFeature"
            case limitName = "limit_name"
            case limitNameCamel = "limitName"
            case rateLimit = "rate_limit"
            case rateLimitCamel = "rateLimit"
            case primaryWindow = "primary_window"
            case primaryWindowCamel = "primaryWindow"
            case primary
            case secondaryWindow = "secondary_window"
            case secondaryWindowCamel = "secondaryWindow"
            case secondary
            case limitSnapshot = "limit_snapshot"
            case limitSnapshotCamel = "limitSnapshot"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.limitId = Self.decodeFirst(
                String.self,
                from: container,
                keys: [.limitId, .limitIdCamel, .meteredFeature, .meteredFeatureCamel])
            self.limitName = Self.decodeFirst(String.self, from: container, keys: [.limitName, .limitNameCamel])
            let nestedRateLimit = Self.decodeFirst(
                RateLimitDetails.self,
                from: container,
                keys: [.rateLimit, .rateLimitCamel])
            let primaryWindow = Self.decodeFirst(
                WindowSnapshot.self,
                from: container,
                keys: [.primaryWindow, .primaryWindowCamel, .primary])
            let secondaryWindow = Self.decodeFirst(
                WindowSnapshot.self,
                from: container,
                keys: [.secondaryWindow, .secondaryWindowCamel, .secondary])
            self.primaryWindow = primaryWindow ?? nestedRateLimit?.primaryWindow
            self.secondaryWindow = secondaryWindow ?? nestedRateLimit?.secondaryWindow
            self.limitSnapshot = Self.decodeFirst(
                WindowSnapshot.self,
                from: container,
                keys: [.limitSnapshot, .limitSnapshotCamel])
        }

        private static func decodeFirst<T: Decodable>(
            _ type: T.Type,
            from container: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]) -> T?
        {
            for key in keys {
                if let value = try? container.decodeIfPresent(type, forKey: key) {
                    return value
                }
            }
            return nil
        }
    }

    public struct WindowSnapshot: Decodable, Sendable {
        public let usedPercent: Int
        public let resetAt: Int
        public let limitWindowSeconds: Int

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case usedPercentCamel = "usedPercent"
            case resetAt = "reset_at"
            case resetAtCamel = "resetAt"
            case resetsAt
            case limitWindowSeconds = "limit_window_seconds"
            case limitWindowSecondsCamel = "limitWindowSeconds"
            case windowDurationMins
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.usedPercent = try Self.decodeFirst(
                Int.self,
                from: container,
                keys: [.usedPercent, .usedPercentCamel])
            self.resetAt = try Self.decodeFirst(
                Int.self,
                from: container,
                keys: [.resetAt, .resetAtCamel, .resetsAt])
            if let seconds = try Self.decodeFirstIfPresent(
                Int.self,
                from: container,
                keys: [.limitWindowSeconds, .limitWindowSecondsCamel])
            {
                self.limitWindowSeconds = seconds
            } else {
                self.limitWindowSeconds = try Self.decodeFirst(
                    Int.self,
                    from: container,
                    keys: [.windowDurationMins]) * 60
            }
        }

        private static func decodeFirst<T: Decodable>(
            _ type: T.Type,
            from container: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]) throws -> T
        {
            if let value = try decodeFirstIfPresent(type, from: container, keys: keys) {
                return value
            }
            throw DecodingError.keyNotFound(
                keys[0],
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Expected one of \(keys.map(\.stringValue).joined(separator: ", "))"))
        }

        private static func decodeFirstIfPresent<T: Decodable>(
            _ type: T.Type,
            from container: KeyedDecodingContainer<CodingKeys>,
            keys: [CodingKeys]) throws -> T?
        {
            for key in keys {
                if let value = try container.decodeIfPresent(type, forKey: key) {
                    return value
                }
            }
            return nil
        }
    }

    public struct CreditDetails: Decodable, Sendable {
        public let hasCredits: Bool
        public let unlimited: Bool
        public let balance: Double?

        enum CodingKeys: String, CodingKey {
            case hasCredits = "has_credits"
            case unlimited
            case balance
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.hasCredits = (try? container.decode(Bool.self, forKey: .hasCredits)) ?? false
            self.unlimited = (try? container.decode(Bool.self, forKey: .unlimited)) ?? false
            if let balance = try? container.decode(Double.self, forKey: .balance) {
                self.balance = balance
            } else if let balance = try? container.decode(String.self, forKey: .balance),
                      let value = Double(balance)
            {
                self.balance = value
            } else {
                self.balance = nil
            }
        }
    }
}

public enum CodexOAuthFetchError: LocalizedError, Sendable {
    case unauthorized
    case invalidResponse
    case serverError(Int, String?)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Codex OAuth token expired or invalid. Run `codex` to re-authenticate."
        case .invalidResponse:
            return "Invalid response from Codex usage API."
        case let .serverError(code, message):
            if let message, !message.isEmpty {
                return "Codex API error \(code): \(message)"
            }
            return "Codex API error \(code)."
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

public enum CodexOAuthUsageFetcher {
    private static let defaultChatGPTBaseURL = "https://chatgpt.com/backend-api/"
    private static let chatGPTUsagePath = "/wham/usage"
    private static let codexUsagePath = "/api/codex/usage"

    public static func fetchUsage(
        accessToken: String,
        accountId: String?,
        env: [String: String] = ProcessInfo.processInfo.environment) async throws -> CodexUsageResponse
    {
        var request = URLRequest(url: Self.resolveUsageURL(env: env))
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("CodexBar", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accountId, !accountId.isEmpty {
            request.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CodexOAuthFetchError.invalidResponse
            }

            switch http.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(CodexUsageResponse.self, from: data)
                } catch {
                    throw CodexOAuthFetchError.invalidResponse
                }
            case 401, 403:
                throw CodexOAuthFetchError.unauthorized
            default:
                let body = String(data: data, encoding: .utf8)
                throw CodexOAuthFetchError.serverError(http.statusCode, body)
            }
        } catch let error as CodexOAuthFetchError {
            throw error
        } catch {
            throw CodexOAuthFetchError.networkError(error)
        }
    }

    private static func resolveUsageURL(env: [String: String]) -> URL {
        self.resolveUsageURL(env: env, configContents: nil)
    }

    private static func resolveUsageURL(env: [String: String], configContents: String?) -> URL {
        let baseURL = self.resolveChatGPTBaseURL(env: env, configContents: configContents)
        let normalized = self.normalizeChatGPTBaseURL(baseURL)
        let path = normalized.contains("/backend-api") ? Self.chatGPTUsagePath : Self.codexUsagePath
        let full = normalized + path
        return URL(string: full) ?? URL(string: Self.defaultChatGPTBaseURL + Self.chatGPTUsagePath)!
    }

    private static func resolveChatGPTBaseURL(env: [String: String], configContents: String?) -> String {
        if let configContents, let parsed = self.parseChatGPTBaseURL(from: configContents) {
            return parsed
        }
        if let contents = self.loadConfigContents(env: env),
           let parsed = self.parseChatGPTBaseURL(from: contents)
        {
            return parsed
        }
        return Self.defaultChatGPTBaseURL
    }

    private static func normalizeChatGPTBaseURL(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { trimmed = Self.defaultChatGPTBaseURL }
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        if trimmed.hasPrefix("https://chatgpt.com") || trimmed.hasPrefix("https://chat.openai.com"),
           !trimmed.contains("/backend-api")
        {
            trimmed += "/backend-api"
        }
        return trimmed
    }

    private static func parseChatGPTBaseURL(from contents: String) -> String? {
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: true).first
            let trimmed = line?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard key == "chatgpt_base_url" else { continue }
            var value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\""), value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            } else if value.hasPrefix("'"), value.hasSuffix("'") {
                value = String(value.dropFirst().dropLast())
            }
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func loadConfigContents(env: [String: String]) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let codexHome = env["CODEX_HOME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let root = (codexHome?.isEmpty == false) ? URL(fileURLWithPath: codexHome!) : home
            .appendingPathComponent(".codex")
        let url = root.appendingPathComponent("config.toml")
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

#if DEBUG
extension CodexOAuthUsageFetcher {
    static func _resolveUsageURLForTesting(env: [String: String] = [:], configContents: String? = nil) -> URL {
        self.resolveUsageURL(env: env, configContents: configContents)
    }

    static func _decodeUsageResponseForTesting(_ data: Data) throws -> CodexUsageResponse {
        try JSONDecoder().decode(CodexUsageResponse.self, from: data)
    }
}
#endif
