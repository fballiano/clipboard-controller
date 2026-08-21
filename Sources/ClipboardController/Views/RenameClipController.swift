import AppKit
import SwiftUI

/// Asks for the name of a clip in its own small window.
///
/// The app has no ordinary window, so AppKit drives this one. The window floats
/// and the app activates, because the menu closes as soon as the user selects
/// the command and the app is not the front application.
@MainActor
final class RenameClipController: NSObject {
    private var window: NSWindow?
    private var pendingSubmit: ((String) -> Void)?

    /// Shows the prompt. If one is already open, the earlier one closes without
    /// a change.
    func present(title: String, name: String, onSubmit: @escaping (String) -> Void) {
        dismiss()
        pendingSubmit = onSubmit

        let view = RenameClipView(clipTitle: title, name: name) { [weak self] newName in
            self?.resolve(with: newName)
        } onCancel: { [weak self] in
            self?.cancel()
        }

        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Rename the clip"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self
        window.center()

        self.window = window

        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func resolve(with name: String) {
        let submit = pendingSubmit
        pendingSubmit = nil
        dismiss()
        submit?(name)
    }

    private func cancel() {
        pendingSubmit = nil
        dismiss()
    }

    private func dismiss() {
        guard let window else { return }

        self.window = nil
        window.delegate = nil
        window.close()
    }
}

extension RenameClipController: NSWindowDelegate {
    /// The user closed the window with the red button: keep the old name.
    func windowWillClose(_ notification: Notification) {
        window = nil
        pendingSubmit = nil
    }
}

private struct RenameClipView: View {
    let clipTitle: String
    @State private var name: String
    @FocusState private var isFocused: Bool

    let onSubmit: (String) -> Void
    let onCancel: () -> Void

    init(
        clipTitle: String,
        name: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.clipTitle = clipTitle
        _name = State(initialValue: name)
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(clipTitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { onSubmit(name) }

            Text("An empty name gives the first line of the text back.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { onSubmit(name) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear { isFocused = true }
    }
}
