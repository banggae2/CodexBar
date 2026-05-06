import CodexBarCore

@MainActor
extension StatusItemController {
    func runJetBrainsLoginFlow() async {
        self.loginPhase = .idle
        let detectedIDEs = JetBrainsIDEDetector.detectInstalledIDEs(includeMissingQuota: true)
        if detectedIDEs.isEmpty {
            let message = [
                L10n.string("Install a JetBrains IDE with AI Assistant enabled, then refresh CodexBar."),
                L10n.string("Alternatively, set a custom path in Settings."),
            ].joined(separator: " ")
            self.presentLoginAlert(
                title: L10n.string("No JetBrains IDE detected"),
                message: message)
        } else {
            let ideNames = detectedIDEs.prefix(3).map(\.displayName).joined(separator: ", ")
            let hasQuotaFile = !JetBrainsIDEDetector.detectInstalledIDEs().isEmpty
            let message = hasQuotaFile
                ? L10n.string("JetBrains detected select IDE format", ideNames)
                : L10n.string("JetBrains detected use assistant format", ideNames)
            self.presentLoginAlert(
                title: L10n.string("JetBrains AI is ready"),
                message: message)
        }
    }
}
