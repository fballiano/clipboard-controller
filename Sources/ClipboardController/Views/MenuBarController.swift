import AppKit

/// The item in the menu bar and the menu that drops from it.
///
/// AppKit builds this menu, and SwiftUI does not. SwiftUI draws the icon of a
/// menu row at the height of the text, and no value changes that, so the
/// picture of an image clip stayed small. An `NSMenuItem` keeps the size of its
/// image and makes its row as tall as the picture.
///
/// The order is: the privacy switch, the two commands of the cleaner, the clips,
/// then the application items.
///
/// Private mode is first, and it has its own group. A user reaches for it when
/// something private is about to go on the clipboard, so it must be the item
/// under the pointer, not an item to look for.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    /// The width and the height of the picture of a clip row.
    private static let iconSide = ImageSupport.thumbnailSide

    private let model: AppModel
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(model: AppModel) {
        self.model = model
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        // The menu holds its own state, so AppKit must not switch an item off.
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
        statusItem.button?.image = glyph

        observePrivateMode()
    }

    // MARK: - The menu bar item

    /// The board, or the board with a line through it while private mode is on.
    /// The user must see at a glance that the app stores nothing.
    private var glyph: NSImage {
        model.privateMode ? ClipboardGlyph.menuBarPrivate : ClipboardGlyph.menuBar
    }

    /// A hot key and a script also switch private mode, so the icon follows the
    /// model and not the menu.
    private func observePrivateMode() {
        withObservationTracking {
            _ = model.privateMode
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.statusItem.button?.image = self.glyph
                self.observePrivateMode()
            }
        }
    }

    // MARK: - The menu

    /// AppKit asks before it opens the menu, so the list is always the list of
    /// this moment.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        add(
            to: menu,
            title: String(localized: "Private mode"),
            action: #selector(togglePrivateMode),
            key: "p",
            modifiers: [.command, .shift],
            state: model.privateMode
        )

        menu.addItem(.separator())

        add(
            to: menu,
            title: String(localized: "Automatic cleaning"),
            action: #selector(toggleAutomaticCleaning),
            state: model.automaticCleaning
        )
        add(to: menu, title: String(localized: "Clean the clipboard now"), action: #selector(cleanNow))

        addClips(to: menu)

        if let storeError = model.storeError {
            menu.addItem(.separator())
            add(
                to: menu,
                title: String(localized: "Database error: \(storeError)"),
                action: nil,
                enabled: false
            )
        }

        menu.addItem(.separator())

        add(to: menu, title: String(localized: "Search…"), action: #selector(showHistory), key: "f")
        add(to: menu, title: String(localized: "Export…"), action: #selector(export))
        add(
            to: menu,
            title: String(localized: "Clear the history"),
            action: #selector(clearHistory),
            enabled: !model.clips.isEmpty
        )

        menu.addItem(.separator())

        add(to: menu, title: String(localized: "Preferences…"), action: #selector(showSettings), key: ",")
        add(to: menu, title: String(localized: "About clipboard-controller"), action: #selector(showAbout))

        menu.addItem(.separator())

        add(to: menu, title: String(localized: "Quit clipboard-controller"), action: #selector(quit), key: "q")
    }

    /// The pinned clips, then the newest clips. The first nine rows of the two
    /// groups together get Command+1 to Command+9.
    private func addClips(to menu: NSMenu) {
        var number = 1

        if !model.pinnedClips.isEmpty {
            menu.addItem(.separator())
            menu.addItem(.sectionHeader(title: String(localized: "Pinned")))

            for clip in model.pinnedClips {
                menu.addItem(clipItem(for: clip, number: number))
                number += 1
            }
        }

        if !model.menuClips.isEmpty {
            menu.addItem(.separator())

            for clip in model.menuClips {
                menu.addItem(clipItem(for: clip, number: number))
                number += 1
            }
        }
    }

    /// One clip. A click copies it, and the submenu holds the rest of the
    /// commands, so the first and shortest way stays the common one.
    private func clipItem(for clip: Clip, number: Int) -> NSMenuItem {
        let item = NSMenuItem(
            title: clip.title,
            action: #selector(copyClip(_:)),
            keyEquivalent: number <= 9 ? "\(number)" : ""
        )
        item.target = self
        item.representedObject = clip

        if let data = clip.thumbnailData {
            item.image = ImageSupport.squareIcon(from: data, side: Self.iconSide)
        }

        item.submenu = commands(for: clip)
        return item
    }

    private func commands(for clip: Clip) -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        add(to: submenu, title: String(localized: "Copy"), action: #selector(copyClip(_:)), clip: clip)

        if clip.richData != nil {
            add(
                to: submenu,
                title: String(localized: "Copy as plain text"),
                action: #selector(copyClipAsPlainText(_:)),
                clip: clip
            )
        }

        add(
            to: submenu,
            title: clip.isPinned ? String(localized: "Unpin") : String(localized: "Pin"),
            action: #selector(togglePin(_:)),
            clip: clip
        )
        add(to: submenu, title: String(localized: "Rename…"), action: #selector(rename(_:)), clip: clip)

        submenu.addItem(.separator())

        add(to: submenu, title: String(localized: "Delete"), action: #selector(delete(_:)), clip: clip)

        return submenu
    }

    @discardableResult
    private func add(
        to menu: NSMenu,
        title: String,
        action: Selector?,
        key: String = "",
        modifiers: NSEvent.ModifierFlags = .command,
        state: Bool = false,
        enabled: Bool = true,
        clip: Clip? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        item.keyEquivalentModifierMask = modifiers
        item.state = state ? .on : .off
        item.isEnabled = enabled && action != nil
        item.representedObject = clip
        menu.addItem(item)
        return item
    }

    // MARK: - The commands

    private func clip(of sender: Any?) -> Clip? {
        (sender as? NSMenuItem)?.representedObject as? Clip
    }

    @objc private func togglePrivateMode() { model.togglePrivateMode() }
    @objc private func toggleAutomaticCleaning() { model.toggleAutomaticCleaning() }
    @objc private func cleanNow() { model.cleanNow() }
    @objc private func showHistory() { model.showHistory() }
    @objc private func export() { model.export() }
    @objc private func clearHistory() { model.clearHistory() }
    @objc private func showSettings() { model.showSettings() }
    @objc private func showAbout() { model.showAbout() }
    @objc private func quit() { model.quit() }

    @objc private func copyClip(_ sender: Any?) {
        guard let clip = clip(of: sender) else { return }
        model.copy(clip)
    }

    @objc private func copyClipAsPlainText(_ sender: Any?) {
        guard let clip = clip(of: sender) else { return }
        model.copy(clip, asPlainText: true)
    }

    @objc private func togglePin(_ sender: Any?) {
        guard let clip = clip(of: sender) else { return }
        model.togglePin(clip)
    }

    @objc private func rename(_ sender: Any?) {
        guard let clip = clip(of: sender) else { return }
        model.rename(clip)
    }

    @objc private func delete(_ sender: Any?) {
        guard let clip = clip(of: sender) else { return }
        model.delete(clip)
    }
}
