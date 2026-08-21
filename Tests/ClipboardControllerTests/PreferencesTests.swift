import Foundation
import Testing
@testable import ClipboardController

@MainActor
@Suite("Preferences")
struct PreferencesTests {
    private func makeDefaults() -> UserDefaults {
        let name = "clipboard-controller.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("The app starts with a safe set of values")
    func defaultValues() {
        let preferences = Preferences(defaults: makeDefaults())

        #expect(preferences.recordClipboard)
        #expect(!preferences.privateMode)
        #expect(preferences.storeImages)
        #expect(preferences.automaticCleaning)
        #expect(preferences.removeFormatting)
        #expect(!preferences.preserveLinks)
        #expect(preferences.removeInvisibleCharacters)
        #expect(preferences.removeTrackingParameters)
        #expect(preferences.maxStoredClips == Preferences.defaultClipLimit)
        #expect(preferences.maxClipAgeDays == Preferences.unlimited)
        #expect(preferences.menuClipCount == Preferences.defaultMenuClipCount)
        #expect(preferences.excludedRecordingApps.isEmpty)
    }

    @Test("A change is written to the store")
    func writesThrough() {
        let defaults = makeDefaults()
        let preferences = Preferences(defaults: defaults)

        preferences.automaticCleaning = false
        preferences.maxStoredClips = 42
        preferences.excludedRecordingApps = ["com.apple.Terminal"]

        #expect(defaults.bool(forKey: Preferences.Key.automaticCleaning) == false)
        #expect(defaults.integer(forKey: Preferences.Key.maxStoredClips) == 42)

        // A new instance reads the same values back.
        let reloaded = Preferences(defaults: defaults)
        #expect(!reloaded.automaticCleaning)
        #expect(reloaded.maxStoredClips == 42)
        #expect(reloaded.excludedRecordingApps == ["com.apple.Terminal"])
    }

    @Test("The limit switch turns the pruning on and off")
    func limitSwitch() {
        let preferences = Preferences(defaults: makeDefaults())

        #expect(preferences.limitsStoredClips)

        preferences.limitsStoredClips = false
        #expect(preferences.maxStoredClips == Preferences.unlimited)

        preferences.limitsStoredClips = true
        #expect(preferences.maxStoredClips == Preferences.defaultClipLimit)
    }

    @Test("The age limit turns into seconds")
    func ageLimit() {
        let preferences = Preferences(defaults: makeDefaults())

        #expect(preferences.maxClipAge == nil)

        preferences.maxClipAgeDays = 2

        // The value is bound first. Inside `#expect` the macro reads each part
        // on its own, and a bare literal there becomes an `Int`.
        let twoDays: TimeInterval = 2 * 24 * 60 * 60
        #expect(preferences.maxClipAge == twoDays)
    }

    @Test("A negative value becomes zero")
    func clampsNegative() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.maxStoredClips = -5
        preferences.maxClipAgeDays = -1

        #expect(preferences.maxStoredClips == 0)
        #expect(preferences.maxClipAgeDays == 0)
    }

    @Test("The number of clips in the menu has two ends")
    func menuCountLimits() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.menuClipCount = 0
        #expect(preferences.menuClipCount == 1)

        preferences.menuClipCount = 500
        #expect(preferences.menuClipCount == 50)
    }

    @Test("An application is added only once")
    func addsApplicationOnce() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.addExcludedRecordingApp("com.apple.Terminal")
        preferences.addExcludedRecordingApp("com.apple.Terminal")
        preferences.addExcludedRecordingApp("")

        #expect(preferences.excludedRecordingApps == ["com.apple.Terminal"])
    }

    @Test("The switches become the options of the cleaner")
    func sanitizerOptions() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.normalizeQuotes = true
        preferences.trimWhitespace = false

        let options = preferences.sanitizerOptions
        #expect(options.normalizeQuotes)
        #expect(!options.trimWhitespace)
        #expect(options.removeTrackingParameters)
    }

    @Test("The settings become the policy of the watcher")
    func clipboardPolicy() {
        let preferences = Preferences(defaults: makeDefaults())

        preferences.privateMode = true
        preferences.excludedCleaningApps = ["com.apple.dt.Xcode"]

        let policy = preferences.clipboardPolicy
        #expect(policy.privateMode)
        #expect(policy.excludedCleaningApps == ["com.apple.dt.Xcode"])
        #expect(policy.recordClipboard)
    }
}
