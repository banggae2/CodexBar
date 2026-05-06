import CodexBarCore
import Foundation

extension SettingsStore {
    struct ProviderDetectionEnablement: Equatable, Sendable {
        let codex: Bool
        let claude: Bool
        let gemini: Bool
        let antigravity: Bool
    }

    static func providerDetectionEnablement(
        codexInstalled: Bool,
        claudeInstalled: Bool,
        geminiInstalled: Bool,
        antigravityRunning: Bool) -> ProviderDetectionEnablement
    {
        // If none installed, keep Codex enabled to match previous behavior.
        let noneInstalled = !codexInstalled && !claudeInstalled && !geminiInstalled && !antigravityRunning
        return ProviderDetectionEnablement(
            codex: codexInstalled || noneInstalled,
            claude: claudeInstalled,
            gemini: false,
            antigravity: antigravityRunning)
    }

    func runInitialProviderDetectionIfNeeded(force: Bool = false) {
        guard force || !self.providerDetectionCompleted else { return }
        LoginShellPathCache.shared.captureOnce { [weak self] _ in
            Task { @MainActor in
                await self?.applyProviderDetection()
            }
        }
    }

    func applyProviderDetection() async {
        guard !self.providerDetectionCompleted else { return }
        let codexInstalled = BinaryLocator.resolveCodexBinary() != nil
        let claudeInstalled = BinaryLocator.resolveClaudeBinary() != nil
        let geminiInstalled = BinaryLocator.resolveGeminiBinary() != nil
        let antigravityRunning = await AntigravityStatusProbe.isRunning()
        let logger = CodexBarLog.logger(LogCategories.providerDetection)
        let enablement = Self.providerDetectionEnablement(
            codexInstalled: codexInstalled,
            claudeInstalled: claudeInstalled,
            geminiInstalled: geminiInstalled,
            antigravityRunning: antigravityRunning)

        logger.info(
            "Provider detection results",
            metadata: [
                "codexInstalled": codexInstalled ? "1" : "0",
                "claudeInstalled": claudeInstalled ? "1" : "0",
                "geminiInstalled": geminiInstalled ? "1" : "0",
                "antigravityRunning": antigravityRunning ? "1" : "0",
            ])
        logger.info(
            "Provider detection enablement",
            metadata: [
                "codex": enablement.codex ? "1" : "0",
                "claude": enablement.claude ? "1" : "0",
                "gemini": enablement.gemini ? "1" : "0",
                "antigravity": enablement.antigravity ? "1" : "0",
            ])

        self.updateProviderConfig(provider: .codex) { entry in
            entry.enabled = enablement.codex
        }
        self.updateProviderConfig(provider: .claude) { entry in
            entry.enabled = enablement.claude
        }
        self.updateProviderConfig(provider: .gemini) { entry in
            entry.enabled = enablement.gemini
        }
        self.updateProviderConfig(provider: .antigravity) { entry in
            entry.enabled = enablement.antigravity
        }
        self.providerDetectionCompleted = true
        logger.info("Provider detection completed")
    }
}
