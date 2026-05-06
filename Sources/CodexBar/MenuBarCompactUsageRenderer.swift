import AppKit
import CodexBarCore

enum MenuBarCompactUsageRenderer {
    static let maxProviders = 5

    struct Entry: Equatable {
        let provider: UsageProvider
        let code: String
        let percent: Double?
        let secondaryPercent: Double?
        let color: ProviderColor

        init(
            provider: UsageProvider,
            code: String,
            percent: Double?,
            secondaryPercent: Double? = nil,
            color: ProviderColor)
        {
            self.provider = provider
            self.code = code
            self.percent = percent
            self.secondaryPercent = secondaryPercent
            self.color = color
        }
    }

    private static let providerCodes: [UsageProvider: String] = [
        .codex: "cx",
        .claude: "cc",
        .cursor: "cu",
        .opencode: "oc",
        .opencodego: "ocßg",
        .alibaba: "ab",
        .factory: "dr",
        .gemini: "gm",
        .antigravity: "ag",
        .copilot: "cp",
        .zai: "za",
        .minimax: "mx",
        .kimi: "km",
        .kilo: "kl",
        .kiro: "kr",
        .vertexai: "vx",
        .augment: "au",
        .jetbrains: "jb",
        .kimik2: "k2",
        .amp: "ap",
        .ollama: "ol",
        .synthetic: "sy",
        .warp: "wp",
        .openrouter: "or",
        .perplexity: "px",
        .abacus: "aa",
        .mistral: "ms",
        .deepseek: "ds",
    ]

    static func providerCode(for provider: UsageProvider) -> String {
        self.providerCodes[provider] ?? String(provider.rawValue.prefix(2))
    }

    static func rowGroups<EntryType>(_ entries: [EntryType]) -> [[EntryType]] {
        guard entries.count > 1 else { return entries.isEmpty ? [] : [entries] }
        let firstRowCount = Int(ceil(Double(entries.count) / 2))
        return [
            Array(entries.prefix(firstRowCount)),
            Array(entries.dropFirst(firstRowCount)),
        ].filter { !$0.isEmpty }
    }

    static func segmentFillCount(percent: Double?, segments: Int = 5) -> Int {
        guard let percent else { return 0 }
        let clamped = min(100, max(0, percent))
        return min(segments, max(0, Int((clamped / 100 * Double(segments)).rounded())))
    }

    static func percentText(for entry: Entry) -> String {
        let primaryText = self.percentComponentText(for: entry.percent)
        guard let secondaryPercent = entry.secondaryPercent else { return primaryText }
        return "\(primaryText)/\(self.percentComponentText(for: secondaryPercent))"
    }

    @MainActor
    static func image(entries: [Entry]) -> NSImage? {
        let limited = Array(entries.prefix(Self.maxProviders))
        guard !limited.isEmpty else { return nil }

        let rows = self.rowGroups(limited)
        let layout = Layout(entries: limited)
        let rowWidths = rows.map { row in
            row.reduce(0) { $0 + layout.entryWidth(for: $1) } + CGFloat(max(0, row.count - 1)) * layout.entrySpacing
        }
        let width = max(rowWidths.max() ?? layout.minWidth, layout.minWidth)
        let height = layout.rowHeight * CGFloat(rows.count) + layout.verticalPadding * 2
        let image = NSImage(size: NSSize(width: ceil(width), height: ceil(height)))

        image.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .none
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: image.size).fill()

        for (rowIndex, row) in rows.enumerated() {
            let rowWidth = rowWidths[rowIndex]
            var x = (image.size.width - rowWidth) / 2
            let y = image.size.height - layout.verticalPadding - CGFloat(rowIndex + 1) * layout.rowHeight
            for entry in row {
                layout.draw(entry: entry, at: NSPoint(x: x, y: y))
                x += layout.entryWidth(for: entry) + layout.entrySpacing
            }
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func percentComponentText(for percent: Double?) -> String {
        percent.map { String(format: "%.0f%%", min(100, max(0, $0))) } ?? "--"
    }
}

private struct Layout {
    let rowHeight: CGFloat = 9
    let verticalPadding: CGFloat = 1
    let entrySpacing: CGFloat = 5
    let codeWidth: CGFloat
    let barWidth: CGFloat = 19
    let percentWidth: CGFloat
    let minWidth: CGFloat = 44
    let textGap: CGFloat = 2

    private var font: NSFont {
        NSFont.monospacedSystemFont(ofSize: 8.5, weight: .semibold)
    }

    init(entries: [MenuBarCompactUsageRenderer.Entry]) {
        self.codeWidth = max(14, Self.measuredTextWidth(entries.map(\.code)))
        self.percentWidth = max(
            17,
            Self.measuredTextWidth(entries.map(Self.percentText(for:))))
    }

    func entryWidth(for _: MenuBarCompactUsageRenderer.Entry) -> CGFloat {
        self.codeWidth + self.textGap + self.barWidth + self.textGap + self.percentWidth
    }

    @MainActor
    func draw(entry: MenuBarCompactUsageRenderer.Entry, at origin: NSPoint) {
        let textY = origin.y + 0.4
        self.drawText(entry.code, at: NSPoint(x: origin.x, y: textY), width: self.codeWidth, color: .labelColor)

        let barX = origin.x + self.codeWidth + self.textGap
        self.drawBar(entry: entry, rect: NSRect(x: barX, y: origin.y + 2.1, width: self.barWidth, height: 3.8))

        let percentX = barX + self.barWidth + self.textGap
        let percentText = Self.percentText(for: entry)
        self.drawText(percentText, at: NSPoint(x: percentX, y: textY), width: self.percentWidth, color: .labelColor)
    }

    static func percentText(for entry: MenuBarCompactUsageRenderer.Entry) -> String {
        MenuBarCompactUsageRenderer.percentText(for: entry)
    }

    private static func measuredTextWidth(_ strings: [String]) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 8.5, weight: .semibold),
        ]
        let maxWidth = strings
            .map { ($0 as NSString).size(withAttributes: attributes).width }
            .max() ?? 0
        return ceil(maxWidth) + 1
    }

    @MainActor
    private func drawText(_ text: String, at origin: NSPoint, width: CGFloat, color: NSColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ]
        text.draw(
            in: NSRect(x: origin.x, y: origin.y, width: width, height: self.rowHeight),
            withAttributes: attributes)
    }

    @MainActor
    private func drawBar(entry: MenuBarCompactUsageRenderer.Entry, rect: NSRect) {
        let radius = rect.height / 2
        let track = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        NSColor.tertiaryLabelColor.withAlphaComponent(0.38).setFill()
        track.fill()

        guard let percent = entry.percent else { return }
        let clamped = min(100, max(0, percent))
        guard clamped > 0 else { return }

        NSGraphicsContext.saveGraphicsState()
        track.addClip()
        entry.color.nsColor.setFill()
        NSRect(x: rect.minX, y: rect.minY, width: rect.width * CGFloat(clamped / 100), height: rect.height).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

extension ProviderColor {
    fileprivate var nsColor: NSColor {
        NSColor(
            calibratedRed: CGFloat(self.red),
            green: CGFloat(self.green),
            blue: CGFloat(self.blue),
            alpha: 1)
    }
}
