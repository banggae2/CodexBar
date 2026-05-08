import Testing
import UserNotifications
@testable import CodexBar

struct NotificationAuthorizationStateTests {
    @Test
    func `authorized notifications show allowed checked status with settings action`() {
        let presentation = AppNotificationAuthorizationState.authorized.presentation

        #expect(presentation.statusTitleKey == "Allowed")
        #expect(presentation.statusSystemImage == "checkmark.circle.fill")
        #expect(presentation.allowsNotificationDisplay)
        #expect(!presentation.showsAllowAction)
    }

    @Test
    func `undetermined notifications show pending status with enabled allow action`() {
        let presentation = AppNotificationAuthorizationState.notDetermined.presentation

        #expect(presentation.statusTitleKey == "Not requested")
        #expect(presentation.statusSystemImage == "questionmark.circle.fill")
        #expect(!presentation.allowsNotificationDisplay)
        #expect(presentation.showsAllowAction)
    }

    @Test
    func `denied notifications show blocked status with enabled allow action`() {
        let presentation = AppNotificationAuthorizationState.denied.presentation

        #expect(presentation.statusTitleKey == "Not allowed")
        #expect(presentation.statusSystemImage == "xmark.circle.fill")
        #expect(!presentation.allowsNotificationDisplay)
        #expect(presentation.showsAllowAction)
    }

    @Test
    @MainActor
    func `provider notification content includes attachment when provider image is available`() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NotificationAuthorizationStateTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageURL = directory.appending(path: "claude.png")
        try Self.onePixelPNG.write(to: imageURL)

        let content = AppNotifications.notificationContent(
            title: "Claude session alert",
            body: "Claude 5h usage 90%",
            badge: nil,
            provider: .claude,
            attachmentURLProvider: { provider in
                provider == .claude ? imageURL : nil
            })

        #expect(content.title == "Claude session alert")
        #expect(content.body == "Claude 5h usage 90%")
        #expect(content.attachments.count == 1)
        #expect(content.attachments.first?.identifier == "provider-claude")
    }

    private static var onePixelPNG: Data {
        Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGOSHzRgAAAAABJRU5ErkJggg==")!
    }
}
