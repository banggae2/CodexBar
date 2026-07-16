import Foundation
import Testing
@testable import CodexBar

struct LocalizedDurationTextTests {
    @Test
    func `duration value keeps English compact units`() {
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.english.rawValue) {
            #expect(LocalizedDurationText.valueDescription(minutes: 4 * 24 * 60 + 19 * 60) == "4d 19h")
            #expect(LocalizedDurationText.valueDescription(minutes: 45) == "45m")
        }
    }

    @Test
    func `duration value localizes Korean units without future suffix`() {
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.korean.rawValue) {
            #expect(LocalizedDurationText.valueDescription(minutes: 4 * 24 * 60 + 19 * 60) == "4일 19시간")
            #expect(LocalizedDurationText.valueDescription(minutes: 45) == "45분")
        }
    }

    @Test
    func `future duration wraps localized value once`() {
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.english.rawValue) {
            #expect(LocalizedDurationText.futureDescription(minutes: 4 * 24 * 60 + 19 * 60) == "in 4d 19h")
        }
        CodexBarLocalizationOverride.$appLanguage.withValue(AppLanguage.korean.rawValue) {
            #expect(LocalizedDurationText.futureDescription(minutes: 4 * 24 * 60 + 19 * 60) == "4일 19시간 후")
        }
    }
}
