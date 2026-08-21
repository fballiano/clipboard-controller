import Foundation
import Testing
@testable import ClipboardController

@MainActor
@Suite("ClipStore")
struct ClipStoreTests {
    private func makeStore() throws -> ClipStore {
        ClipStore(container: try ClipStore.makeContainer(inMemory: true))
    }

    private func text(_ value: String, source: String = "TextEdit") -> ClipboardContent {
        ClipboardContent(
            kind: .plainText,
            text: value,
            byteCount: value.utf8.count,
            sourceBundleID: "com.apple.TextEdit",
            sourceAppName: source
        )
    }

    // MARK: - Add

    @Test("A clip is stored")
    func addsClip() throws {
        let store = try makeStore()

        store.add(text("hello"))

        #expect(store.count == 1)
        #expect(store.all().first?.text == "hello")
    }

    @Test("The same content does not make a second row")
    func deduplicates() throws {
        let store = try makeStore()

        store.add(text("hello"), date: Date(timeIntervalSince1970: 100))
        store.add(text("world"), date: Date(timeIntervalSince1970: 200))
        store.add(text("hello"), date: Date(timeIntervalSince1970: 300))

        #expect(store.count == 2)

        // The old row moved to the top and counts one more use.
        let all = store.all()
        #expect(all.first?.text == "hello")
        #expect(all.first?.useCount == 1)
    }

    // MARK: - Pin

    @Test("A pinned clip comes first")
    func pinnedFirst() throws {
        let store = try makeStore()

        let first = store.add(text("one"), date: Date(timeIntervalSince1970: 100))
        store.add(text("two"), date: Date(timeIntervalSince1970: 200))

        store.togglePin(first)

        #expect(store.all().first?.text == "one")
    }

    @Test("A prune never deletes a pinned clip")
    func pruneKeepsPinned() throws {
        let store = try makeStore()

        let pinned = store.add(text("keep me"), date: Date(timeIntervalSince1970: 100))
        store.togglePin(pinned)

        for index in 1 ... 10 {
            store.add(text("clip \(index)"), date: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        store.prune(keeping: 3)

        let all = store.all()
        #expect(all.count == 4) // The pinned clip and three others.
        #expect(all.first?.text == "keep me")
    }

    @Test("A prune deletes the oldest clips above the limit")
    func prunesToLimit() throws {
        let store = try makeStore()

        for index in 1 ... 10 {
            store.add(text("clip \(index)"), date: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        store.prune(keeping: 4)

        #expect(store.count == 4)
        #expect(store.all().first?.text == "clip 10")
    }

    @Test("A limit of zero keeps every clip")
    func zeroLimitKeepsAll() throws {
        let store = try makeStore()

        for index in 1 ... 5 {
            store.add(text("clip \(index)"), date: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        store.prune(keeping: 0)

        #expect(store.count == 5)
    }

    @Test("A clip that is too old goes")
    func prunesByAge() throws {
        let store = try makeStore()
        let now = Date(timeIntervalSince1970: 1_000_000)

        store.add(text("old"), date: now.addingTimeInterval(-10 * 86_400))
        store.add(text("new"), date: now.addingTimeInterval(-1 * 86_400))

        store.prune(keeping: 0, olderThan: 5 * 86_400, now: now)

        #expect(store.count == 1)
        #expect(store.all().first?.text == "new")
    }

    // MARK: - Clear

    @Test("Clear keeps the pinned clips")
    func clearKeepsPinned() throws {
        let store = try makeStore()

        let pinned = store.add(text("keep me"))
        store.togglePin(pinned)
        store.add(text("throw away"))

        store.clear()

        #expect(store.count == 1)
        #expect(store.all().first?.text == "keep me")
    }

    @Test("A full clear deletes everything")
    func clearsEverything() throws {
        let store = try makeStore()

        let pinned = store.add(text("keep me"))
        store.togglePin(pinned)

        store.clear(keepPinned: false)

        #expect(store.count == 0)
    }

    // MARK: - Search and rename

    @Test("The search reads the text, the name and the application")
    func search() throws {
        let store = try makeStore()

        store.add(text("the quick brown fox"))
        store.add(text("another thing", source: "Safari"))

        #expect(store.search("QUICK").count == 1)
        #expect(store.search("safari").count == 1)
        #expect(store.search("").count == 2)
        #expect(store.search("nothing here").isEmpty)
    }

    @Test("A new name is found by the search")
    func rename() throws {
        let store = try makeStore()
        let clip = store.add(text("aaa"))

        store.rename(clip, to: "  My address  ")

        #expect(clip.customName == "My address")
        #expect(store.search("address").count == 1)
    }

    // MARK: - Export

    @Test("The export holds one row for each clip, newest first")
    func export() throws {
        let store = try makeStore()

        store.add(text("one"), date: Date(timeIntervalSince1970: 100))
        store.add(text("two"), date: Date(timeIntervalSince1970: 200))

        let records = store.records()

        #expect(records.count == 2)
        #expect(records.first?.text == "two")
        #expect(records.first?.kind == "plainText")

        let data = try store.exportData()
        #expect(!data.isEmpty)
    }

    @Test("The name of the export file holds the date")
    func exportFileName() {
        let name = ClipStore.exportFileName(for: Date(timeIntervalSince1970: 0))

        #expect(name.hasPrefix("clipboard-controller-"))
        #expect(name.hasSuffix(".json"))
    }
}
