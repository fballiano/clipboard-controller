import SwiftUI

/// The menu that drops down from the menu bar.
///
/// The order is: the three switches of the cleaner and of the privacy, the
/// clips, then the application items.
struct MenuContent: View {
    let model: AppModel

    var body: some View {
        Toggle("Automatic cleaning", isOn: Binding(
            get: { model.automaticCleaning },
            set: { model.setAutomaticCleaning($0) }
        ))

        Button("Clean the clipboard now") { model.cleanNow() }

        Toggle("Private mode", isOn: Binding(
            get: { model.privateMode },
            set: { model.setPrivateMode($0) }
        ))

        if !model.pinnedClips.isEmpty {
            Divider()

            Section("Pinned") {
                ForEach(Array(model.pinnedClips.enumerated()), id: \.element.persistentModelID) { index, clip in
                    ClipMenuRow(model: model, clip: clip, number: index + 1)
                }
            }
        }

        if !model.menuClips.isEmpty {
            Divider()

            ForEach(Array(model.menuClips.enumerated()), id: \.element.persistentModelID) { index, clip in
                ClipMenuRow(
                    model: model,
                    clip: clip,
                    number: model.pinnedClips.count + index + 1
                )
            }
        }

        if let storeError = model.storeError {
            Divider()
            Text("Database error: \(storeError)")
        }

        Divider()

        Button("Search…") { model.showHistory() }
            .keyboardShortcut("f", modifiers: .command)

        Button("Export…") { model.export() }

        Button("Clear the history") { model.clearHistory() }
            .disabled(model.clips.isEmpty)

        Divider()

        Button("Preferences…") { model.showSettings() }
            .keyboardShortcut(",", modifiers: .command)

        Button("About clipboard-controller") { model.showAbout() }

        Divider()

        Button("Quit clipboard-controller") { model.quit() }
            .keyboardShortcut("q", modifiers: .command)
    }
}
