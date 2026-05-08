import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum ClaudeOAuthFetchError: LocalizedError, Sendable {
    case unauthorized
    case invalidResponse
    case serverError(Int, String?)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Claude OAuth request unauthorized. Run `claude` to re-authenticate."
        case .invalidResponse:
            return "Claude OAuth response was invalid."
        case let .serverError(code, body):
            if let body, !body.isEmpty {
                let cleaned = body
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let shortened = cleaned.count > 400 ? String(cleaned.prefix(400)) + "…" : cleaned
                return "Claude OAuth error: HTTP \(code) – \(shortened)"
            }
            return "Claude OAuth error: HTTP \(code)"
        case let .networkError(error):
            return "Claude OAuth network error: \(error.localizedDescription)"
        }
    }
}

enum ClaudeOAuthUsageFetcher {
    private static let usageURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private static let fallbackClaudeCodeVersion = "2.1.0"
    #if DEBUG
    @TaskLocal private static var dataLoaderOverride: (@Sendable (URLRequest) async throws -> (Data, URLResponse))?
    #endif

    static func fetchUsage(accessToken: String) async throws -> OAuthUsageResponse {
        var request = URLRequest(url: self.usageURL, timeoutInterval: 5)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(self.claudeCodeUserAgent(), forHTTPHeaderField: "User-Agent")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        let data: Data
        let response: URLResponse
        do {
            #if DEBUG
            if let dataLoaderOverride {
                (data, response) = try await dataLoaderOverride(request)
            } else {
                (data, response) = try await URLSession.shared.data(for: request)
            }
            #else
            (data, response) = try await URLSession.shared.data(for: request)
            #endif
        } catch {
            throw ClaudeOAuthFetchError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeOAuthFetchError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            if http.statusCode == 401 {
                throw ClaudeOAuthFetchError.unauthorized
            }
            throw ClaudeOAuthFetchError.serverError(http.statusCode, body)
        }

        do {
            return try self.decodeUsageResponse(data)
        } catch {
            throw ClaudeOAuthFetchError.invalidResponse
        }
    }

    static func decodeUsageResponse(_ data: Data) throws -> OAuthUsageResponse {
        let decoder = JSONDecoder()
        if let envelope = try? decoder.decode(OAuthUsageEnvelope.self, from: data),
           let usage = envelope.data
        {
            return usage
        }
        return try decoder.decode(OAuthUsageResponse.self, from: data)
    }

    static func parseISO8601Date(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private static func claudeCodeUserAgent() -> String {
        self.claudeCodeUserAgent(versionString: ProviderVersionDetector.claudeVersion())
    }

    private static func claudeCodeUserAgent(versionString: String?) -> String {
        let version = self.normalizedClaudeCodeVersion(versionString) ?? self.fallbackClaudeCodeVersion
        return "claude-code/\(version)"
    }

    private static func normalizedClaudeCodeVersion(_ versionString: String?) -> String? {
        guard let raw = versionString?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        let token = raw.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? raw
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct OAuthUsageEnvelope: Decodable {
    let data: OAuthUsageResponse?
}

struct OAuthUsageResponse: Decodable {
    let fiveHour: OAuthUsageWindow?
    let sevenDay: OAuthUsageWindow?
    let sevenDayOAuthApps: OAuthUsageWindow?
    let sevenDayOpus: OAuthUsageWindow?
    let sevenDaySonnet: OAuthUsageWindow?
    let sevenDayDesign: OAuthUsageWindow?
    let sevenDayRoutines: OAuthUsageWindow?
    let sevenDayDesignSourceKey: String?
    let sevenDayRoutinesSourceKey: String?
    let iguanaNecktie: OAuthUsageWindow?
    let extraUsage: OAuthExtraUsage?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        self.fiveHour = Self.decodeWindow(in: container, keys: ["five_hour"])
        self.sevenDay = Self.decodeWindow(in: container, keys: ["seven_day"])
        self.sevenDayOAuthApps = Self.decodeWindow(in: container, keys: ["seven_day_oauth_apps"])
        self.sevenDayOpus = Self.decodeWindow(in: container, keys: ["seven_day_opus"])
        self.sevenDaySonnet = Self.decodeWindow(in: container, keys: ["seven_day_sonnet"])
        let design = Self.decodeWindowWithSource(in: container, keys: [
            "seven_day_design",
            "seven_day_claude_design",
            "claude_design",
            "design",
            "seven_day_omelette",
            "omelette",
            "omelette_promotional",
        ])
        self.sevenDayDesign = design.window
        self.sevenDayDesignSourceKey = design.sourceKey
        let routines = Self.decodeWindowWithSource(in: container, keys: [
            "seven_day_routines",
            "seven_day_claude_routines",
            "claude_routines",
            "routines",
            "routine",
            "seven_day_cowork",
            "cowork",
        ])
        self.sevenDayRoutines = routines.window
        self.sevenDayRoutinesSourceKey = routines.sourceKey
        self.iguanaNecktie = Self.decodeWindow(in: container, keys: ["iguana_necktie"])
        self.extraUsage = Self.decodeValue(in: container, keys: ["extra_usage"])
    }

    private static func decodeWindow(
        in container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]) -> OAuthUsageWindow?
    {
        self.decodeValue(in: container, keys: keys)
    }

    private static func decodeWindowWithSource(
        in container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]) -> (window: OAuthUsageWindow?, sourceKey: String?)
    {
        var firstNullKey: String?
        for keyName in keys {
            guard let key = DynamicCodingKey(stringValue: keyName) else { continue }
            guard container.contains(key) else { continue }
            if let value = try? container.decodeIfPresent(OAuthUsageWindow.self, forKey: key) {
                return (value, keyName)
            }
            if firstNullKey == nil {
                firstNullKey = keyName
            }
        }
        return (nil, firstNullKey)
    }

    private static func decodeValue<T: Decodable>(
        in container: KeyedDecodingContainer<DynamicCodingKey>,
        keys: [String]) -> T?
    {
        for keyName in keys {
            guard let key = DynamicCodingKey(stringValue: keyName) else { continue }
            if let value = try? container.decodeIfPresent(T.self, forKey: key) {
                return value
            }
        }
        return nil
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        nil
    }
}

struct OAuthUsageWindow: Decodable {
    let utilization: Double?
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

struct OAuthExtraUsage: Decodable {
    let isEnabled: Bool?
    let monthlyLimit: Double?
    let usedCredits: Double?
    let utilization: Double?
    let currency: String?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case monthlyLimit = "monthly_limit"
        case usedCredits = "used_credits"
        case utilization
        case currency
    }
}

#if DEBUG
extension ClaudeOAuthUsageFetcher {
    static func _decodeUsageResponseForTesting(_ data: Data) throws -> OAuthUsageResponse {
        try self.decodeUsageResponse(data)
    }

    static func _userAgentForTesting(versionString: String?) -> String {
        self.claudeCodeUserAgent(versionString: versionString)
    }

    static func _withDataLoaderForTesting<T>(
        _ loader: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse),
        operation: () async throws -> T) async rethrows -> T
    {
        try await self.$dataLoaderOverride.withValue(loader) {
            try await operation()
        }
    }
}
#endif
