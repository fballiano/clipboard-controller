import AppKit

/// The start of the application.
///
/// AppKit owns the life of the app, and SwiftUI does not. The menu of the menu
/// bar needs an `NSMenu`, because only AppKit gives a row a picture that is
/// larger than the text. SwiftUI still draws the windows: the history, the
/// preferences and the rename sheet.
@main
@MainActor
enum ClipboardControllerApp {
    /// `NSApplication` keeps no strong reference to its delegate, so the
    /// delegate lives here.
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The tests load into the real application, so the application launches
        // during a test run. It must add no item to the menu bar of the user.
        guard !RuntimeEnvironment.isRunningTests else { return }

        let model = AppModel.shared
        model.bootstrap()
        menuBar = MenuBarController(model: model)
    }
}
