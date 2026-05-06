import Foundation

public enum ClaudeUsageDataSource: String, CaseIterable, Identifiable, Sendable {
    case auto
    case cli
    case log
    case oauth
    case web

    public var id: String {
        self.rawValue
    }

    public var displayName: String {
        switch self {
        case .auto: "Auto"
        case .cli: "CLI (PTY)"
        case .log: "Local logs"
        case .oauth: "OAuth API"
        case .web: "Web API (cookies)"
        }
    }

    public var sourceLabel: String {
        switch self {
        case .auto:
            "auto"
        case .cli:
            "cli"
        case .log:
            "log"
        case .oauth:
            "oauth"
        case .web:
            "web"
        }
    }

    public static let supportedClaudeCodeSources: [ClaudeUsageDataSource] = [.auto, .cli, .log]
}
