import AppKit
import Foundation
@testable import ClipboardController

/// A clipboard that lives in memory.
///
/// The tests must not touch the real clipboard: the user keeps copying while the
/// tests run, and a test that writes there would take the content of the user
/// away.
@MainActor
final class FakePasteboard: PasteboardReading {
    private(set) var changeCount = 0
    private var items: [NSPasteboard.PasteboardType: Data] = [:]

    /// How many times the app wrote to this clipboard.
    private(set) var writeCount = 0

    var types: [NSPasteboard.PasteboardType] { Array(items.keys) }

    func data(forType type: NSPasteboard.PasteboardType) -> Data? { items[type] }

    @discardableResult
    func write(_ items: [(type: NSPasteboard.PasteboardType, data: Data)]) -> Int {
        writeCount += 1
        replace(with: items)
        return changeCount
    }

    /// Another application copied something.
    func copy(_ items: [(type: NSPasteboard.PasteboardType, data: Data)]) {
        replace(with: items)
    }

    /// Another application copied plain text.
    func copy(text: String, markers: [NSPasteboard.PasteboardType] = []) {
        var items: [(type: NSPasteboard.PasteboardType, data: Data)] = [
            (.string, Data(text.utf8)),
        ]
        items += markers.map { ($0, Data()) }

        copy(items)
    }

    private func replace(with items: [(type: NSPasteboard.PasteboardType, data: Data)]) {
        self.items = [:]
        for item in items {
            self.items[item.type] = item.data
        }
        changeCount += 1
    }
}
