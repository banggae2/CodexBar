import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct MenuCardSubtitleTests {
    @Test
    func `subtitle respects selected app language for fresh updates`() throws {
        let previousLanguage = UserDefaults.standard.string(forKey: AppLanguage.userDefaultsKey)
        UserDefaults.standard.set(AppLanguage.korean.rawValue, forKey: AppLanguage.userDefaultsKey)
        defer {
            if let previousLanguage {
                UserDefaults.standard.set(previousLanguage, forKey: AppLanguage.userDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: AppLanguage.userDefaultsKey)
            }
        }

        let updatedAt = Date(timeIntervalSinceReferenceDate: 0)
        let model = try Self.makeModel(updatedAt: updatedAt, now: updatedAt)

        #expect(model.subtitleText == "방금 업데이트됨")
    }

    @Test
    func `subtitle uses injected current time`() throws {
        let updatedAt = Date(timeIntervalSinceReferenceDate: 0)
        let now = updatedAt.addingTimeInterval(5 * 3600)
        let model = try Self.makeModel(updatedAt: updatedAt, now: now)

        #expect(model.subtitleText == AppUsageFormatter.updatedString(from: updatedAt, now: now))
    }

    private static func makeModel(updatedAt: Date, now: Date) throws -> UsageMenuCardView.Model {
        let snapshot = UsageSnapshot(
            primary: RateWindow(
                usedPercent: 22,
                windowMinutes: 300,
                resetsAt: now.addingTimeInterval(3000),
                resetDescription: nil),
            secondary: nil,
            tertiary: nil,
            updatedAt: updatedAt,
            identity: ProviderIdentitySnapshot(
                providerID: .codex,
                accountEmail: "codex@example.com",
                accountOrganization: nil,
                loginMethod: "Plus Plan"))
        let metadata = try #require(ProviderDefaults.metadata[.codex])

        return UsageMenuCardView.Model.make(.init(
            provider: .codex,
            metadata: metadata,
            snapshot: snapshot,
            credits: nil,
            creditsError: nil,
            dashboard: nil,
            dashboardError: nil,
            tokenSnapshot: nil,
            tokenError: nil,
            account: AccountInfo(email: "codex@example.com", plan: "Plus Plan"),
            isRefreshing: false,
            lastError: nil,
            usageBarsShowUsed: false,
            resetTimeDisplayStyle: .countdown,
            tokenCostUsageEnabled: false,
            showOptionalCreditsAndExtraUsage: true,
            hidePersonalInfo: false,
            now: now))
    }
}
