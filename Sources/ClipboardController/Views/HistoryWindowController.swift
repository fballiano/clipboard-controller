import AppKit
import SwiftUI

/// Shows `HistoryView` in its own window.
///
/// The reason is the same as for `SettingsWindowController`: the app is an agent
/// app, so a SwiftUI `Window` scene opens behind the front application. AppKit
/// owns this window, and the code activates the app by hand.
@MainActor
final class HistoryWindowController {
    private var window: NSWindow?

    /// Shows the window, and creates it on the first call. A second call brings
    /// the same window forward instead of opening another one.
    func present(model: AppModel) {
        let window = window ?? makeWindow()
        self.window = window

        // A new view for each call. The search field takes the focus when the
        // view appears, and a view appears only once, so the second call would
        // open the window with nothing in focus. The search text starts empty
        // for the same reason: the window opens for a new search.
        window.contentView = NSHostingView(rootView: HistoryView(model: model))

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 460),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Clipboard history")
        window.setFrameAutosaveName("history")
        // The window is kept for the next call, so it must survive its close.
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
