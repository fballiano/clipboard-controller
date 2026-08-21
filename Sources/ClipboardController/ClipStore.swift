import Foundation
import SwiftData

/// Reads and writes the clipboard history.
@MainActor
final class ClipStore {
    let container: ModelContainer

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    /// Builds the SwiftData container.
    ///
    /// The store gets its own folder. The SwiftData default is
    /// `~/Library/Application Support/default.store`, and this app is not
    /// sandboxed, so that path is shared with every other application of the
    /// user. Two applications would then fight over one file.
    ///
    /// - Parameter inMemory: `true` gives a throw-away store, used by the tests.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(
                for: Clip.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        return try ModelContainer(
            for: Clip.self,
            configurations: ModelConfiguration(url: try storeURL())
        )
    }

    /// `~/Library/Application Support/clipboard-controller/clipboard-controller.store`.
    static func storeURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(path: "clipboard-controller", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory.appending(
            path: "clipboard-controller.store",
            directoryHint: .notDirectory
        )
    }

    // MARK: - Read

    /// Every clip. The pinned clips come first, then the newest.
    func all() -> [Clip] {
        let descriptor = FetchDescriptor<Clip>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let clips = (try? context.fetch(descriptor)) ?? []

        // `Bool` is not `Comparable`, so a sort descriptor cannot put the
        // pinned clips first. The two groups are joined here instead.
        return clips.filter(\.isPinned) + clips.filter { !$0.isPinned }
    }

    /// The first `limit` clips of `all()`.
    func recent(limit: Int) -> [Clip] {
        guard limit > 0 else { return all() }
        return Array(all().prefix(limit))
    }

    /// The clips whose text or name holds the words. An empty query gives
    /// everything.
    func search(_ query: String) -> [Clip] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all() }

        // The match runs in memory, not in a predicate. A predicate cannot read
        // `title`, and the history is small enough for a plain filter.
        return all().filter { clip in
            clip.text.localizedCaseInsensitiveContains(trimmed)
                || clip.customName.localizedCaseInsensitiveContains(trimmed)
                || clip.sourceAppName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// The clip that holds the same content, if the history already holds it.
    func clip(withHash hash: String) -> Clip? {
        var descriptor = FetchDescriptor<Clip>(
            predicate: #Predicate { $0.contentHash == hash }
        )
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<Clip>())) ?? 0
    }

    // MARK: - Write

    /// Stores one clip, then prunes the old ones.
    ///
    /// A second copy of the same content does not add a second row. The old row
    /// moves to the top and counts one more use, which is the behaviour of every
    /// clipboard manager.
    ///
    /// - Returns: the stored clip, new or moved.
    @discardableResult
    func add(
        _ content: ClipboardContent,
        date: Date = .now,
        keeping limit: Int = 0
    ) -> Clip {
        let hash = Clip.hash(kind: content.kind, text: content.text, imageData: content.imageData)

        if let existing = clip(withHash: hash) {
            existing.date = date
            existing.useCount += 1

            // The source can change: the same words copied from another app.
            if !content.sourceBundleID.isEmpty {
                existing.sourceBundleID = content.sourceBundleID
                existing.sourceAppName = content.sourceAppName
            }

            save()
            return existing
        }

        let clip = Clip(
            date: date,
            kind: content.kind,
            text: content.text,
            richData: content.richData,
            richType: content.richType,
            imageData: content.imageData,
            thumbnailData: content.thumbnailData,
            pixelWidth: content.pixelWidth,
            pixelHeight: content.pixelHeight,
            byteCount: content.byteCount,
            sourceBundleID: content.sourceBundleID,
            sourceAppName: content.sourceAppName,
            contentHash: hash
        )

        context.insert(clip)
        prune(keeping: limit)
        save()

        return clip
    }

    func delete(_ clip: Clip) {
        context.delete(clip)
        save()
    }

    func togglePin(_ clip: Clip) {
        clip.isPinned.toggle()
        save()
    }

    func rename(_ clip: Clip, to name: String) {
        clip.customName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func markUsed(_ clip: Clip) {
        clip.useCount += 1
        save()
    }

    /// Deletes the clips above the limit and the clips that are too old.
    ///
    /// A pinned clip never goes. The user pinned it, so the limit does not touch
    /// it, and it does not fill a place of the limit either.
    /// - Parameters:
    ///   - limit: how many clips to keep. `0` or less keeps every clip.
    ///   - maximumAge: delete a clip older than this. `nil` keeps every clip.
    func prune(keeping limit: Int, olderThan maximumAge: TimeInterval? = nil, now: Date = .now) {
        var changed = false

        if let maximumAge, maximumAge > 0 {
            let oldest = now.addingTimeInterval(-maximumAge)

            for clip in all() where !clip.isPinned && clip.date < oldest {
                context.delete(clip)
                changed = true
            }
        }

        if limit > 0 {
            let unpinned = all().filter { !$0.isPinned }

            if unpinned.count > limit {
                for clip in unpinned[limit...] {
                    context.delete(clip)
                    changed = true
                }
            }
        }

        if changed { save() }
    }

    /// Deletes every clip that is not pinned.
    func clear(keepPinned: Bool = true) {
        for clip in all() where !(keepPinned && clip.isPinned) {
            context.delete(clip)
        }
        save()
    }

    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    // MARK: - Export

    /// One row of the export file.
    struct Record: Codable, Equatable {
        let date: String
        let kind: String
        let title: String
        let text: String
        let source: String
        let pinned: Bool
        let useCount: Int
    }

    func records() -> [Record] {
        all().map { clip in
            Record(
                date: Self.exportDateFormatter.string(from: clip.date),
                kind: clip.kindRaw,
                title: clip.title,
                // An image holds no text, so the file stays readable.
                text: clip.kind == .image ? "" : clip.text,
                source: clip.sourceAppName,
                pinned: clip.isPinned,
                useCount: clip.useCount
            )
        }
    }

    func exportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(records())
    }

    /// The suggested file name, for example `clipboard-controller-2026-08-21.json`.
    static func exportFileName(for date: Date = .now) -> String {
        "clipboard-controller-\(fileDateFormatter.string(from: date)).json"
    }

    private static let exportDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter
    }()

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
