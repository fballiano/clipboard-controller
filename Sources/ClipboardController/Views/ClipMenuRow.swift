import SwiftUI

/// One clip in the menu.
///
/// A click copies the clip. The submenu holds the rest of the commands, so the
/// first and shortest way stays the common one.
struct ClipMenuRow: View {
    let model: AppModel
    let clip: Clip

    /// The place in the menu, from 1. The first nine rows get a shortcut.
    let number: Int

    var body: some View {
        Menu {
            Button("Copy") { model.copy(clip) }

            if clip.richData != nil {
                Button("Copy as plain text") { model.copy(clip, asPlainText: true) }
            }

            Button(clip.isPinned ? "Unpin" : "Pin") { model.togglePin(clip) }
            Button("Rename…") { model.rename(clip) }

            Divider()

            Button("Delete") { model.delete(clip) }
        } label: {
            label
        } primaryAction: {
            model.copy(clip)
        }
        .modifier(NumberShortcut(number: number))
    }

    @ViewBuilder
    private var label: some View {
        if let data = clip.thumbnailData, let image = NSImage(data: data) {
            Label {
                Text(clip.title)
            } icon: {
                Image(nsImage: image)
                    .renderingMode(.original)
            }
        } else {
            Label(clip.title, systemImage: symbol)
        }
    }

    private var symbol: String {
        if clip.isPinned { return "pin.fill" }

        switch clip.kind {
        case .url: return "link"
        case .richText: return "textformat"
        case .image: return "photo"
        case .plainText: return "text.alignleft"
        }
    }
}

/// Gives Command+1 to Command+9 to the first nine rows.
///
/// A `keyboardShortcut` needs a `KeyEquivalent`, and a number above nine has two
/// characters, so the rest of the rows get nothing.
private struct NumberShortcut: ViewModifier {
    let number: Int

    func body(content: Content) -> some View {
        if (1 ... 9).contains(number) {
            content.keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: .command)
        } else {
            content
        }
    }
}
