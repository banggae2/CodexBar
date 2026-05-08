import CodexBarCore
import Foundation
@preconcurrency import UserNotifications

struct AppNotificationAuthorizationPresentation: Equatable {
    let statusTitleKey: String
    let statusSystemImage: String
    let allowsNotificationDisplay: Bool
    let showsAllowAction: Bool
}

enum AppNotificationAuthorizationState: Equatable {
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional

    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        case .provisional:
            self = .provisional
        @unknown default:
            self = .unknown
        }
    }

    var presentation: AppNotificationAuthorizationPresentation {
        switch self {
        case .authorized, .provisional:
            AppNotificationAuthorizationPresentation(
                statusTitleKey: "Allowed",
                statusSystemImage: "checkmark.circle.fill",
                allowsNotificationDisplay: true,
                showsAllowAction: false)
        case .notDetermined:
            AppNotificationAuthorizationPresentation(
                statusTitleKey: "Not requested",
                statusSystemImage: "questionmark.circle.fill",
                allowsNotificationDisplay: false,
                showsAllowAction: true)
        case .denied:
            AppNotificationAuthorizationPresentation(
                statusTitleKey: "Not allowed",
                statusSystemImage: "xmark.circle.fill",
                allowsNotificationDisplay: false,
                showsAllowAction: true)
        case .unknown:
            AppNotificationAuthorizationPresentation(
                statusTitleKey: "Checking...",
                statusSystemImage: "questionmark.circle.fill",
                allowsNotificationDisplay: false,
                showsAllowAction: false)
        }
    }
}

@MainActor
final class AppNotifications {
    static let shared = AppNotifications()

    private let centerProvider: @Sendable () -> UNUserNotificationCenter
    private let logger = CodexBarLog.logger(LogCategories.notifications)
    private var authorizationTask: Task<Bool, Never>?

    init(centerProvider: @escaping @Sendable () -> UNUserNotificationCenter = { UNUserNotificationCenter.current() }) {
        self.centerProvider = centerProvider
    }

    func requestAuthorizationOnStartup() {
        guard !Self.isRunningUnderTests else { return }
        _ = self.ensureAuthorizationTask()
    }

    func authorizationState() async -> AppNotificationAuthorizationState {
        guard !Self.isRunningUnderTests else { return .unknown }
        guard let status = await self.notificationAuthorizationStatus() else { return .unknown }
        return AppNotificationAuthorizationState(status: status)
    }

    func post(
        idPrefix: String,
        title: String,
        body: String,
        badge: NSNumber? = nil,
        provider: UsageProvider? = nil)
    {
        guard !Self.isRunningUnderTests else { return }
        let center = self.centerProvider()
        let logger = self.logger

        Task { @MainActor in
            let granted = await self.ensureAuthorized()
            guard granted else {
                logger.debug("not authorized; skipping post", metadata: ["prefix": idPrefix])
                return
            }

            let content = Self.notificationContent(
                title: title,
                body: body,
                badge: badge,
                provider: provider)

            let request = UNNotificationRequest(
                identifier: "codexbar-\(idPrefix)-\(UUID().uuidString)",
                content: content,
                trigger: nil)

            logger.info("posting", metadata: ["prefix": idPrefix])
            do {
                try await center.add(request)
            } catch {
                let errorText = String(describing: error)
                logger.error("failed to post", metadata: ["prefix": idPrefix, "error": errorText])
            }
        }
    }

    static func notificationContent(
        title: String,
        body: String,
        badge: NSNumber?,
        provider: UsageProvider?,
        attachmentURLProvider: (UsageProvider) -> URL? = { ProviderNotificationAttachment.fileURL(for: $0) })
        -> UNMutableNotificationContent
    {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = badge

        if let provider,
           let url = attachmentURLProvider(provider),
           let attachment = try? UNNotificationAttachment(
               identifier: "provider-\(provider.rawValue)",
               url: url,
               options: nil)
        {
            content.attachments = [attachment]
        }

        return content
    }

    // MARK: - Private

    private func ensureAuthorizationTask() -> Task<Bool, Never> {
        if let authorizationTask { return authorizationTask }
        let task = Task { @MainActor in
            await self.requestAuthorization()
        }
        self.authorizationTask = task
        return task
    }

    private func ensureAuthorized() async -> Bool {
        await self.ensureAuthorizationTask().value
    }

    private func requestAuthorization() async -> Bool {
        if let existing = await self.notificationAuthorizationStatus() {
            if existing == .authorized || existing == .provisional {
                return true
            }
            if existing == .denied {
                return false
            }
        }

        let center = self.centerProvider()
        return await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func notificationAuthorizationStatus() async -> UNAuthorizationStatus? {
        let center = self.centerProvider()
        return await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private static var isRunningUnderTests: Bool {
        // Swift Testing doesn't always set XCTest env vars, and removing XCTest imports from
        // the test target can make NSClassFromString("XCTestCase") return nil. If we're not
        // running inside an app bundle, treat it as "tests/headless" to avoid crashes when
        // accessing UNUserNotificationCenter.
        if Bundle.main.bundleURL.pathExtension != "app" { return true }
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil { return true }
        if env["TESTING_LIBRARY_VERSION"] != nil { return true }
        if env["SWIFT_TESTING"] != nil { return true }
        return NSClassFromString("XCTestCase") != nil
    }
}
