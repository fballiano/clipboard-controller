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
        let window = window ?? makeWindow(model: model)
        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow(model: AppModel) -> NSWindow {
        let content = NSHostingView(rootView: HistoryView(model: model))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 460),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = content
        window.title = "Clipboard history"
        window.setFrameAutosaveName("history")
        // The window is kept for the next call, so it must survive its close.
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
