import Foundation
import Observation

/// The user settings, stored in `UserDefaults`.
@MainActor
@Observable
final class Preferences {
    enum Key {
        // The history.
        static let recordClipboard = "recordClipboard"
        static let privateMode = "privateMode"
        static let storeImages = "storeImages"
        static let maxStoredClips = "maxStoredClips"
        static let maxClipAgeDays = "maxClipAgeDays"
        static let maxTextLength = "maxTextLength"
        static let maxImageBytes = "maxImageBytes"
        static let menuClipCount = "menuClipCount"
        static let appliedDefaultLoginItem = "appliedDefaultLoginItem"

        // The cleaner.
        static let automaticCleaning = "automaticCleaning"
        static let removeFormatting = "removeFormatting"
        static let preserveLinks = "preserveLinks"
        static let removeInvisibleCharacters = "removeInvisibleCharacters"
        static let normalizeQuotes = "normalizeQuotes"
        static let normalizeNewlines = "normalizeNewlines"
        static let normalizeLists = "normalizeLists"
        static let trimWhitespace = "trimWhitespace"
        static let removeTrackingParameters = "removeTrackingParameters"

        // Privacy.
        static let excludedRecordingApps = "excludedRecordingApps"
        static let excludedCleaningApps = "excludedCleaningApps"
    }

    /// The value of a limit that means "no limit".
    static let unlimited = 0

    /// The default number of clips to keep.
    static let defaultClipLimit = 200

    /// The default number of clips in the menu.
    static let defaultMenuClipCount = 20

    /// The default longest text, in characters. A longer text is almost always
    /// a whole file, and the history is not a place for a file.
    static let defaultMaxTextLength = 100_000

    /// The default biggest picture, in bytes.
    static let defaultMaxImageBytes = 10 * 1024 * 1024

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        defaults.register(defaults: [
            Key.recordClipboard: true,
            Key.privateMode: false,
            Key.storeImages: true,
            Key.maxStoredClips: Self.defaultClipLimit,
            Key.maxClipAgeDays: Self.unlimited,
            Key.maxTextLength: Self.defaultMaxTextLength,
            Key.maxImageBytes: Self.defaultMaxImageBytes,
            Key.menuClipCount: Self.defaultMenuClipCount,
            Key.appliedDefaultLoginItem: false,
            Key.automaticCleaning: true,
            Key.removeFormatting: true,
            Key.preserveLinks: false,
            Key.removeInvisibleCharacters: true,
            Key.normalizeQuotes: false,
            Key.normalizeNewlines: true,
            Key.normalizeLists: false,
            Key.trimWhitespace: true,
            Key.removeTrackingParameters: true,
            Key.excludedRecordingApps: [String](),
            Key.excludedCleaningApps: [String](),
        ])

        recordClipboard = defaults.bool(forKey: Key.recordClipboard)
        privateMode = defaults.bool(forKey: Key.privateMode)
        storeImages = defaults.bool(forKey: Key.storeImages)
        storedMaxClips = max(0, defaults.integer(forKey: Key.maxStoredClips))
        storedMaxClipAgeDays = max(0, defaults.integer(forKey: Key.maxClipAgeDays))
        maxTextLength = max(0, defaults.integer(forKey: Key.maxTextLength))
        maxImageBytes = max(0, defaults.integer(forKey: Key.maxImageBytes))
        storedMenuClipCount = max(1, defaults.integer(forKey: Key.menuClipCount))
        appliedDefaultLoginItem = defaults.bool(forKey: Key.appliedDefaultLoginItem)

        automaticCleaning = defaults.bool(forKey: Key.automaticCleaning)
        removeFormatting = defaults.bool(forKey: Key.removeFormatting)
        preserveLinks = defaults.bool(forKey: Key.preserveLinks)
        removeInvisibleCharacters = defaults.bool(forKey: Key.removeInvisibleCharacters)
        normalizeQuotes = defaults.bool(forKey: Key.normalizeQuotes)
        normalizeNewlines = defaults.bool(forKey: Key.normalizeNewlines)
        normalizeLists = defaults.bool(forKey: Key.normalizeLists)
        trimWhitespace = defaults.bool(forKey: Key.trimWhitespace)
        removeTrackingParameters = defaults.bool(forKey: Key.removeTrackingParameters)

        excludedRecordingApps = defaults.stringArray(forKey: Key.excludedRecordingApps) ?? []
        excludedCleaningApps = defaults.stringArray(forKey: Key.excludedCleaningApps) ?? []
    }

    // MARK: - The history

    /// Store what the user copies.
    var recordClipboard: Bool {
        didSet { defaults.set(recordClipboard, forKey: Key.recordClipboard) }
    }

    /// Store nothing while this is on. The state survives a restart, because a
    /// user who turns it on wants it on.
    var privateMode: Bool {
        didSet { defaults.set(privateMode, forKey: Key.privateMode) }
    }

    /// Store the pictures as well as the text.
    var storeImages: Bool {
        didSet { defaults.set(storeImages, forKey: Key.storeImages) }
    }

    /// The backing value. Never assign to a property inside its own `didSet`:
    /// the `@Observable` macro routes the assignment back through the setter,
    /// which recurses until the stack overflows.
    private var storedMaxClips: Int {
        didSet { defaults.set(storedMaxClips, forKey: Key.maxStoredClips) }
    }

    /// How many clips to keep. `0` keeps every clip.
    var maxStoredClips: Int {
        get { storedMaxClips }
        set { storedMaxClips = max(0, newValue) }
    }

    /// `true` when the app deletes the old clips.
    var limitsStoredClips: Bool {
        get { maxStoredClips != Self.unlimited }
        set { maxStoredClips = newValue ? Self.defaultClipLimit : Self.unlimited }
    }

    private var storedMaxClipAgeDays: Int {
        didSet { defaults.set(storedMaxClipAgeDays, forKey: Key.maxClipAgeDays) }
    }

    /// Delete a clip after this many days. `0` keeps every clip.
    var maxClipAgeDays: Int {
        get { storedMaxClipAgeDays }
        set { storedMaxClipAgeDays = max(0, newValue) }
    }

    /// `true` when the app deletes a clip because of its age.
    var limitsClipAge: Bool {
        get { maxClipAgeDays != Self.unlimited }
        set { maxClipAgeDays = newValue ? 30 : Self.unlimited }
    }

    /// The age limit in seconds, or `nil` when there is no limit.
    var maxClipAge: TimeInterval? {
        maxClipAgeDays > 0 ? TimeInterval(maxClipAgeDays) * 24 * 60 * 60 : nil
    }

    /// Do not store a text longer than this. `0` means no limit.
    var maxTextLength: Int {
        didSet { defaults.set(maxTextLength, forKey: Key.maxTextLength) }
    }

    /// Do not store a picture bigger than this, in bytes. `0` means no limit.
    var maxImageBytes: Int {
        didSet { defaults.set(maxImageBytes, forKey: Key.maxImageBytes) }
    }

    private var storedMenuClipCount: Int {
        didSet { defaults.set(storedMenuClipCount, forKey: Key.menuClipCount) }
    }

    /// How many clips the menu shows. A menu that is longer than the screen is
    /// hard to use, so the value has an upper end.
    var menuClipCount: Int {
        get { storedMenuClipCount }
        set { storedMenuClipCount = min(max(1, newValue), 50) }
    }

    /// `true` after the app has registered the login item once.
    ///
    /// The app starts at login by default, so the first launch registers the
    /// login item. This flag stops it from doing that a second time. Without it
    /// the app would switch the setting back on at every launch, and a user who
    /// turned it off could never keep it off.
    var appliedDefaultLoginItem: Bool {
        didSet { defaults.set(appliedDefaultLoginItem, forKey: Key.appliedDefaultLoginItem) }
    }

    // MARK: - The cleaner

    var automaticCleaning: Bool {
        didSet { defaults.set(automaticCleaning, forKey: Key.automaticCleaning) }
    }

    var removeFormatting: Bool {
        didSet { defaults.set(removeFormatting, forKey: Key.removeFormatting) }
    }

    var preserveLinks: Bool {
        didSet { defaults.set(preserveLinks, forKey: Key.preserveLinks) }
    }

    var removeInvisibleCharacters: Bool {
        didSet { defaults.set(removeInvisibleCharacters, forKey: Key.removeInvisibleCharacters) }
    }

    var normalizeQuotes: Bool {
        didSet { defaults.set(normalizeQuotes, forKey: Key.normalizeQuotes) }
    }

    var normalizeNewlines: Bool {
        didSet { defaults.set(normalizeNewlines, forKey: Key.normalizeNewlines) }
    }

    var normalizeLists: Bool {
        didSet { defaults.set(normalizeLists, forKey: Key.normalizeLists) }
    }

    var trimWhitespace: Bool {
        didSet { defaults.set(trimWhitespace, forKey: Key.trimWhitespace) }
    }

    var removeTrackingParameters: Bool {
        didSet { defaults.set(removeTrackingParameters, forKey: Key.removeTrackingParameters) }
    }

    /// The rules of the text cleaner, as one value for `Sanitizer`.
    var sanitizerOptions: Sanitizer.Options {
        Sanitizer.Options(
            removeInvisibleCharacters: removeInvisibleCharacters,
            normalizeQuotes: normalizeQuotes,
            normalizeNewlines: normalizeNewlines,
            normalizeLists: normalizeLists,
            trimWhitespace: trimWhitespace,
            removeTrackingParameters: removeTrackingParameters
        )
    }

    // MARK: - Privacy

    /// The bundle identifiers of the applications that the history ignores.
    var excludedRecordingApps: [String] {
        didSet { defaults.set(excludedRecordingApps, forKey: Key.excludedRecordingApps) }
    }

    /// The bundle identifiers of the applications that the cleaner ignores.
    var excludedCleaningApps: [String] {
        didSet { defaults.set(excludedCleaningApps, forKey: Key.excludedCleaningApps) }
    }

    func addExcludedRecordingApp(_ bundleID: String) {
        guard !bundleID.isEmpty, !excludedRecordingApps.contains(bundleID) else { return }
        excludedRecordingApps.append(bundleID)
    }

    func addExcludedCleaningApp(_ bundleID: String) {
        guard !bundleID.isEmpty, !excludedCleaningApps.contains(bundleID) else { return }
        excludedCleaningApps.append(bundleID)
    }

    // MARK: - The whole picture

    /// The settings that `ClipboardMonitor` reads at each change.
    var clipboardPolicy: ClipboardPolicy {
        ClipboardPolicy(
            recordClipboard: recordClipboard,
            privateMode: privateMode,
            automaticCleaning: automaticCleaning,
            storeImages: storeImages,
            removeFormatting: removeFormatting,
            preserveLinks: preserveLinks,
            sanitizer: sanitizerOptions,
            excludedRecordingApps: Set(excludedRecordingApps),
            excludedCleaningApps: Set(excludedCleaningApps),
            maxTextLength: maxTextLength,
            maxImageBytes: maxImageBytes
        )
    }
}
