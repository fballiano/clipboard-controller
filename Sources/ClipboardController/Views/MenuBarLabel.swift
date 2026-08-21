import SwiftUI

/// What the menu bar shows.
///
/// The board, or the board with a line through it while the private mode is on.
/// The user must see at a glance that the app stores nothing.
///
/// The icon is the same Tabler outline as the application icon, drawn as a
/// template image, so it follows the menu bar between light and dark and it
/// inverts while the menu is open.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        Image(nsImage: model.privateMode ? ClipboardGlyph.menuBarPrivate : ClipboardGlyph.menuBar)
            .renderingMode(.template)
    }
}
