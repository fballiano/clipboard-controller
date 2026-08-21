import SwiftData
import SwiftUI

/// The whole history with a search field.
///
/// The menu shows the newest clips only, because a long menu is hard to use.
/// This window reaches every clip.
struct HistoryView: View {
    let model: AppModel

    @State private var query = ""
    @State private var selection: PersistentIdentifier?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            list
            Divider()
            footer
        }
        .frame(minWidth: 520, minHeight: 380)
        // The focus waits for one turn of the run loop, because the window is
        // not the key window yet while the view appears.
        .task { isSearchFocused = true }
    }

    // MARK: - The parts

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search the history", text: $query)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(results) { clip in
                HistoryRow(clip: clip)
                    .tag(clip.persistentModelID)
                    .contextMenu {
                        Button("Copy") { model.copy(clip) }

                        if clip.richData != nil {
                            Button("Copy as plain text") { model.copy(clip, asPlainText: true) }
                        }

                        Button(clip.isPinned ? "Unpin" : "Pin") { model.togglePin(clip) }
                        Button("Rename…") { model.rename(clip) }

                        Divider()

                        Button("Delete") { model.delete(clip) }
                    }
            }
        }
        .listStyle(.inset)
        .contextMenu(forSelectionType: PersistentIdentifier.self) { _ in
        } primaryAction: { identifiers in
            // A double click on a row copies it.
            guard let id = identifiers.first, let clip = clip(withID: id) else { return }
            model.copy(clip)
        }
    }

    private var footer: some View {
        HStack {
            Text(countText)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Copy") { copySelected() }
                .disabled(selectedClip == nil)
                .keyboardShortcut(.defaultAction)

            Button("Delete") { deleteSelected() }
                .disabled(selectedClip == nil)
        }
        .padding(10)
    }

    // MARK: - The data

    private var results: [Clip] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return model.clips }

        return model.clips.filter { clip in
            clip.text.localizedCaseInsensitiveContains(trimmed)
                || clip.customName.localizedCaseInsensitiveContains(trimmed)
                || clip.sourceAppName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var countText: String {
        let count = results.count
        if count == model.clips.count { return "\(count) clips" }
        return "\(count) of \(model.clips.count) clips"
    }

    private var selectedClip: Clip? {
        guard let selection else { return nil }
        return clip(withID: selection)
    }

    private func clip(withID id: PersistentIdentifier) -> Clip? {
        model.clips.first { $0.persistentModelID == id }
    }

    private func copySelected() {
        guard let clip = selectedClip else { return }
        model.copy(clip)
    }

    private func deleteSelected() {
        guard let clip = selectedClip else { return }
        selection = nil
        model.delete(clip)
    }
}

/// One row of the list.
private struct HistoryRow: View {
    let clip: Clip

    var body: some View {
        HStack(spacing: 10) {
            icon
                .frame(width: ImageSupport.thumbnailSide, height: ImageSupport.thumbnailSide)

            VStack(alignment: .leading, spacing: 2) {
                Text(clip.title)
                    .lineLimit(1)

                Text(clip.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if clip.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    /// The picture of an image clip. A text clip keeps the empty space, so
    /// every title of the list keeps the same left edge.
    ///
    /// A symbol for the kind is gone: the second line of the row already names
    /// the kind, and the same symbol on every row says nothing.
    @ViewBuilder
    private var icon: some View {
        if let data = clip.thumbnailData, let image = NSImage(data: data) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
