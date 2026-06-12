import CodexBarCore
import Testing
@testable import CodexBar

struct AugmentSessionKeepaliveSecurityTests {
    @Test
    func `cookie summaries do not include values`() {
        let summary = AugmentSessionKeepalive.safeCookieSummary("auth=secret-token; sid=session-id")

        #expect(summary.contains("auth"))
        #expect(summary.contains("sid"))
        #expect(!summary.contains("secret-token"))
        #expect(!summary.contains("session-id"))
    }
}
