import CodexBarCore
import Foundation
@preconcurrency import UserNotifications

enum SessionQuotaTransition: Equatable {
    case none
    case depleted
    case restored
    case usageThreshold(Int)
    case weeklyUsageThreshold(Int)
    case weeklyRestored
}

enum SessionQuotaNotificationLogic {
    static let depletedThreshold: Double = 0.0001
    static let defaultUsageThresholds: [Int] = [25, 50, 75, 100]

    static func isDepleted(_ remaining: Double?) -> Bool {
        guard let remaining else { return false }
        return remaining <= Self.depletedThreshold
    }

    static func transition(previousRemaining: Double?, currentRemaining: Double?) -> SessionQuotaTransition {
        guard let currentRemaining else { return .none }
        guard let previousRemaining else { return .none }

        let wasDepleted = previousRemaining <= Self.depletedThreshold
        let isDepleted = currentRemaining <= Self.depletedThreshold

        if !wasDepleted, isDepleted { return .depleted }
        if wasDepleted, !isDepleted { return .restored }
        return .none
    }

    static func normalizedUsageThresholds(_ thresholds: [Int]) -> [Int] {
        Array(Set(thresholds.filter { $0 > 0 && $0 <= 100 })).sorted()
    }

    static func crossedUsageThresholds(
        previousUsed: Double?,
        currentUsed: Double?,
        thresholds: [Int],
        alreadySent: Set<Int>) -> [Int]
    {
        guard let currentUsed else { return [] }
        let normalized = self.normalizedUsageThresholds(thresholds)
        let crossed = normalized.filter { threshold in
            guard !alreadySent.contains(threshold) else { return false }
            guard currentUsed >= Double(threshold) else { return false }
            guard let previousUsed else { return true }
            let thresholdValue = Double(threshold)
            return previousUsed < thresholdValue || (previousUsed == thresholdValue && currentUsed > previousUsed)
        }
        return crossed.last.map { [$0] } ?? []
    }
}

@MainActor
protocol SessionQuotaNotifying: AnyObject {
    func post(transition: SessionQuotaTransition, provider: UsageProvider, badge: NSNumber?)
}

@MainActor
final class SessionQuotaNotifier: SessionQuotaNotifying {
    private let logger = CodexBarLog.logger(LogCategories.sessionQuotaNotifications)

    init() {}

    func post(transition: SessionQuotaTransition, provider: UsageProvider, badge: NSNumber? = nil) {
        guard transition != .none else { return }

        let providerName = ProviderDescriptorRegistry.descriptor(for: provider).metadata.displayName

        let (title, body) = switch transition {
        case .none:
            ("", "")
        case .depleted:
            (L10n.string("Session depleted title format", providerName), L10n.string("Session depleted body"))
        case .restored:
            (L10n.string("Session restored title format", providerName), L10n.string("Session restored body"))
        case let .usageThreshold(threshold):
            (
                L10n.string("Session usage threshold title format", providerName, threshold),
                L10n.string("Session usage threshold body format", threshold))
        case let .weeklyUsageThreshold(threshold):
            (
                L10n.string("Weekly usage threshold title format", providerName, threshold),
                L10n.string("Weekly usage threshold body format", threshold))
        case .weeklyRestored:
            (
                L10n.string("Weekly limit restored title format", providerName),
                L10n.string("Weekly limit restored body"))
        }

        let providerText = provider.rawValue
        let transitionText = String(describing: transition)
        let idPrefix = "session-\(providerText)-\(transitionText)"
        self.logger.info("enqueuing", metadata: ["prefix": idPrefix])
        AppNotifications.shared.post(idPrefix: idPrefix, title: title, body: body, badge: badge, provider: provider)
    }
}
