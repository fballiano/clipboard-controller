import AppKit
import Foundation
import KeyboardShortcuts
import Observation
import SwiftData
import UniformTypeIdentifiers

/// The one controller of the app.
///
/// Every way in — the menu, a global hot key, an AppleScript command, a
/// Shortcuts action — calls the same methods here, so each command has exactly
/// one code path.
@MainActor
@Observable
final class AppModel {
    static let shared = AppModel()

    let preferences: Preferences
    let loginItem: LoginItem

    /// The clips for the menu and for the history window, pinned first.
    private(set) var clips: [Clip] = []

    /// Set when the database could not be opened.
    private(set) var storeError: String?

    @ObservationIgnored private let store: ClipStore
    @ObservationIgnored private let pasteboard: PasteboardReading
    @ObservationIgnored private let settingsWindow = SettingsWindowController()
    @ObservationIgnored private let historyWindow = HistoryWindowController()
    @ObservationIgnored private let renamePrompt = RenameClipController()
    @ObservationIgnored private var monitor: ClipboardMonitor?
    @ObservationIgnored private var didBootstrap = false

    init(
        store: ClipStore? = nil,
        preferences: Preferences? = nil,
        pasteboard: PasteboardReading? = nil
    ) {
        self.preferences = preferences ?? Preferences()
        self.loginItem = LoginItem()
        self.pasteboard = pasteboard ?? SystemPasteboard()

        if let store {
            self.store = store
        } else {
            // The tests run inside the real app, so they must not touch the
            // live database.
            let inMemory = RuntimeEnvironment.isRunningTests
            do {
                self.store = ClipStore(container: try ClipStore.makeContainer(inMemory: inMemory))
            } catch {
                // Fall back to a throw-away store so the app still runs.
                self.store = ClipStore(
                    container: try! ClipStore.makeContainer(inMemory: true)
                )
                self.storeError = error.localizedDescription
            }
        }

        reloadClips()
    }

    // MARK: - Launch

    /// Wires the clipboard watcher and the hot keys.
    func bootstrap() {
        guard !didBootstrap, !RuntimeEnvironment.isRunningTests else { return }
        didBootstrap = true

        applyLimits()
        applyDefaultLoginItem()
        startMonitor()
        registerHotKeys()
    }

    /// Starts the app at login, once.
    ///
    /// The app has no dock icon and no window, so a user who does not find it
    /// after a restart thinks it is gone. The first launch therefore registers
    /// the login item. A later change by the user stays: the flag says that the
    /// default was applied, so the app never sets it again.
    private func applyDefaultLoginItem() {
        guard !preferences.appliedDefaultLoginItem else { return }

        if loginItem.isEnabled {
            preferences.appliedDefaultLoginItem = true
            return
        }

        loginItem.isEnabled = true

        // Only a registration that worked counts. A failure is tried again at
        // the next launch.
        preferences.appliedDefaultLoginItem = loginItem.isEnabled
    }

    private func startMonitor() {
        let monitor = ClipboardMonitor(
            pasteboard: pasteboard,
            policy: { [weak self] in
                self?.preferences.clipboardPolicy ?? ClipboardPolicy()
            },
            onCapture: { [weak self] content in
                self?.record(content)
            }
        )
        monitor.start()
        self.monitor = monitor
    }

    private func registerHotKeys() {
        KeyboardShortcuts.onKeyDown(for: .toggleAutomaticCleaning) { [weak self] in
            MainActor.assumeIsolated { self?.toggleAutomaticCleaning() }
        }
        KeyboardShortcuts.onKeyDown(for: .cleanNow) { [weak self] in
            MainActor.assumeIsolated { _ = self?.cleanNow() }
        }
        KeyboardShortcuts.onKeyDown(for: .togglePrivateMode) { [weak self] in
            MainActor.assumeIsolated { self?.togglePrivateMode() }
        }
        KeyboardShortcuts.onKeyDown(for: .showHistory) { [weak self] in
            MainActor.assumeIsolated { self?.showHistory() }
        }
    }

    // MARK: - The cleaner

    var automaticCleaning: Bool { preferences.automaticCleaning }

    func setAutomaticCleaning(_ value: Bool) {
        preferences.automaticCleaning = value
    }

    func toggleAutomaticCleaning() {
        setAutomaticCleaning(!preferences.automaticCleaning)
    }

    /// Cleans what is on the clipboard now. The command works even when the
    /// automatic cleaning is off.
    @discardableResult
    func cleanNow() -> Bool {
        monitor?.cleanNow() ?? false
    }

    // MARK: - Privacy

    var privateMode: Bool { preferences.privateMode }

    func setPrivateMode(_ value: Bool) {
        preferences.privateMode = value
    }

    func togglePrivateMode() {
        setPrivateMode(!preferences.privateMode)
    }

    // MARK: - The history

    private func record(_ content: ClipboardContent) {
        store.add(content, keeping: preferences.maxStoredClips)
        applyAgeLimit()
        reloadClips()
    }

    /// Writes the clip back to the clipboard. The user then pastes it.
    func copy(_ clip: Clip, asPlainText: Bool = false) {
        var items: [(type: NSPasteboard.PasteboardType, data: Data)] = []

        if clip.kind == .image, let data = clip.imageData {
            items.append((.png, data))
        } else {
            if !asPlainText,
               let data = clip.richData,
               let raw = clip.richTypeRaw {
                items.append((NSPasteboard.PasteboardType(raw), data))
            }
            items.append((.string, Data(clip.text.utf8)))
        }

        guard !items.isEmpty else { return }

        pasteboard.write(items)

        // The clip is on top of the clipboard now, so the watcher must not store
        // it a second time. `markUsed` counts the use instead.
        monitor?.ignoreCurrentContent()
        store.markUsed(clip)
        reloadClips()
    }

    func togglePin(_ clip: Clip) {
        store.togglePin(clip)
        reloadClips()
    }

    func rename(_ clip: Clip) {
        renamePrompt.present(title: clip.title, name: clip.customName) { [weak self] name in
            guard let self else { return }
            store.rename(clip, to: name)
            reloadClips()
        }
    }

    func delete(_ clip: Clip) {
        store.delete(clip)
        reloadClips()
    }

    /// Deletes every clip that is not pinned.
    func clearHistory() {
        store.clear(keepPinned: true)
        reloadClips()
    }

    /// Deletes every clip, the pinned clips as well.
    func clearHistoryCompletely() {
        store.clear(keepPinned: false)
        reloadClips()
    }

    /// The pinned clips. The menu always shows every one of them.
    var pinnedClips: [Clip] {
        clips.filter(\.isPinned)
    }

    /// The newest clips that are not pinned, up to the limit of the menu.
    var menuClips: [Clip] {
        Array(clips.filter { !$0.isPinned }.prefix(preferences.menuClipCount))
    }

    func clips(matching query: String) -> [Clip] {
        store.search(query)
    }

    /// The text of the newest clip, for AppleScript and for Shortcuts. An empty
    /// history gives an empty string.
    var lastClipText: String {
        clips.first?.text ?? ""
    }

    /// Applies the count limit and the age limit, then reads the list again.
    func applyLimits() {
        store.prune(keeping: preferences.maxStoredClips, olderThan: preferences.maxClipAge)
        reloadClips()
    }

    private func applyAgeLimit() {
        guard let age = preferences.maxClipAge else { return }
        store.prune(keeping: 0, olderThan: age)
    }

    private func reloadClips() {
        clips = store.all()
    }

    // MARK: - Export

    func export() {
        guard let data = try? store.exportData() else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = ClipStore.exportFileName()
        panel.title = "Export the clipboard history"

        NSApp.activate()

        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Panels

    func showSettings() {
        settingsWindow.present(model: self)
    }

    func showHistory() {
        historyWindow.present(model: self)
    }

    func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
