import AppKit
import Foundation

/// The AppleScript commands.
///
///     tell application "clipboard-controller" to clean clipboard
///
/// The class names are exported to the Objective-C runtime, because the
/// scripting definition refers to them by name. Every command calls one method
/// on `AppModel`, the same method that the menu calls.

@objc(CleanClipboardCommand)
final class CleanClipboardCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.cleanNow() }
    }
}

@objc(StartCleaningCommand)
final class StartCleaningCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.setAutomaticCleaning(true) }
        return nil
    }
}

@objc(StopCleaningCommand)
final class StopCleaningCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.setAutomaticCleaning(false) }
        return nil
    }
}

@objc(StartPrivateModeCommand)
final class StartPrivateModeCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.setPrivateMode(true) }
        return nil
    }
}

@objc(StopPrivateModeCommand)
final class StopPrivateModeCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.setPrivateMode(false) }
        return nil
    }
}

/// Returns the text of the newest clip.
@objc(LastClipCommand)
final class LastClipCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.lastClipText }
    }
}

@objc(ClearHistoryCommand)
final class ClearHistoryCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated { AppModel.shared.clearHistory() }
        return nil
    }
}
