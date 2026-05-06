import Foundation

struct CodexLoginAlertInfo: Equatable {
    let title: String
    let message: String
}

enum CodexLoginAlertPresentation {
    static func alertInfo(for result: CodexLoginRunner.Result) -> CodexLoginAlertInfo? {
        switch result.outcome {
        case .success:
            return nil
        case .missingBinary:
            return CodexLoginAlertInfo(
                title: L10n.string("Codex CLI not found"),
                message: L10n.string("Install the Codex CLI and try again."))
        case let .launchFailed(message):
            return CodexLoginAlertInfo(title: L10n.string("Could not start codex login"), message: message)
        case .timedOut:
            return CodexLoginAlertInfo(
                title: L10n.string("Codex login timed out"),
                message: self.trimmedOutput(result.output))
        case let .failed(status):
            let statusLine = L10n.string("codex login exited with status format", status)
            let message = self.trimmedOutput(result.output.isEmpty ? statusLine : result.output)
            return CodexLoginAlertInfo(title: L10n.string("Codex login failed"), message: message)
        }
    }

    private static func trimmedOutput(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let limit = 600
        if trimmed.isEmpty { return L10n.string("No output captured.") }
        if trimmed.count <= limit { return trimmed }
        let idx = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return "\(trimmed[..<idx])…"
    }
}
