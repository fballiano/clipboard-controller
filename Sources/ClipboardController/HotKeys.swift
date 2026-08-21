import KeyboardShortcuts

/// The global hot keys. `KeyboardShortcuts` stores the chosen combinations in
/// `UserDefaults` and turns them off while the user records a new one.
extension KeyboardShortcuts.Name {
    /// Turns the automatic cleaning on and off.
    static let toggleAutomaticCleaning = Self("toggleAutomaticCleaning")

    /// Cleans the content that is on the clipboard now.
    static let cleanNow = Self("cleanNow")

    /// Turns the private mode on and off.
    static let togglePrivateMode = Self("togglePrivateMode")

    /// Opens the history window.
    static let showHistory = Self("showHistory")
}
