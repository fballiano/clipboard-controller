import AppIntents
import Foundation

/// The Shortcuts and Spotlight actions.
///
/// App Intents are the modern equivalent of the AppleScript suite. Both are
/// present, and both call the same methods on `AppModel`.

struct CleanClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Clean Clipboard"
    static let description = IntentDescription(
        "Removes the formatting and the tracking parameters from the content of the clipboard."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        .result(value: AppModel.shared.cleanNow(notify: true))
    }
}

struct SetAutomaticCleaningIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Automatic Cleaning"
    static let description = IntentDescription("Turns the automatic cleaning of the clipboard on or off.")
    static let openAppWhenRun = false

    @Parameter(title: "Automatic cleaning")
    var enabled: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.setAutomaticCleaning(enabled, notify: true)
        return .result()
    }
}

struct SetPrivateModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Private Mode"
    static let description = IntentDescription("Stops or starts the recording of the clipboard.")
    static let openAppWhenRun = false

    @Parameter(title: "Private mode")
    var enabled: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.setPrivateMode(enabled, notify: true)
        return .result()
    }
}

struct LastClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Last Clip"
    static let description = IntentDescription("Returns the text of the newest clip of the history.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: AppModel.shared.lastClipText)
    }
}

struct ClearHistoryIntent: AppIntent {
    static let title: LocalizedStringResource = "Clear Clipboard History"
    static let description = IntentDescription("Deletes every clip that is not pinned.")
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        AppModel.shared.clearHistory()
        return .result()
    }
}

struct ClipboardControllerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CleanClipboardIntent(),
            phrases: ["Clean the clipboard with \(.applicationName)"],
            shortTitle: "Clean Clipboard",
            systemImageName: "wand.and.sparkles"
        )
        AppShortcut(
            intent: LastClipIntent(),
            phrases: ["Get the last clip from \(.applicationName)"],
            shortTitle: "Get Last Clip",
            systemImageName: "doc.on.clipboard"
        )
        AppShortcut(
            intent: ClearHistoryIntent(),
            phrases: ["Clear the history of \(.applicationName)"],
            shortTitle: "Clear History",
            systemImageName: "trash"
        )
    }
}
