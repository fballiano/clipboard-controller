import CryptoKit
import Foundation
import SwiftData

/// What a clip holds.
enum ClipKind: String, Codable, CaseIterable, Sendable {
    case plainText
    case richText
    case url
    case image

    var label: String {
        switch self {
        case .plainText: String(localized: "Text", comment: "The kind of a clip")
        case .richText: String(localized: "Formatted text", comment: "The kind of a clip")
        case .url: String(localized: "Link", comment: "The kind of a clip")
        case .image: String(localized: "Image", comment: "The kind of a clip")
        }
    }
}

/// One entry of the clipboard history.
///
/// The kind is stored as a string, not as an enum. SwiftData builds its queries
/// from the stored properties, and a string works in every predicate.
@Model
final class Clip {
    /// When the user copied it. A second copy of the same content moves this
    /// date forward instead of adding a second row.
    var date: Date

    var kindRaw: String

    /// The plain text. The search reads this. An image clip holds an empty
    /// string here.
    var text: String

    /// The RTF or the HTML of a formatted clip, so the app can put the
    /// formatting back.
    @Attribute(.externalStorage) var richData: Data?

    /// The pasteboard type of `richData`.
    var richTypeRaw: String?

    /// The picture, as a PNG.
    @Attribute(.externalStorage) var imageData: Data?

    /// The small copy of the picture for the menu, as a PNG.
    @Attribute(.externalStorage) var thumbnailData: Data?

    var pixelWidth: Int
    var pixelHeight: Int

    /// The size of the content in bytes.
    var byteCount: Int

    /// The application that was in front when the content arrived.
    var sourceBundleID: String
    var sourceAppName: String

    /// A pinned clip stays at the top of the menu, and a prune never deletes it.
    var isPinned: Bool

    /// A name that the user gave. An empty string means no name.
    var customName: String

    /// How many times the user copied this clip back.
    var useCount: Int

    /// The SHA-256 of the content. The store uses it to find a duplicate.
    ///
    /// The property carries no unique constraint. A unique constraint makes
    /// SwiftData replace the old row without a word, and the store must decide
    /// what happens to a duplicate itself.
    var contentHash: String

    init(
        date: Date = .now,
        kind: ClipKind,
        text: String,
        richData: Data? = nil,
        richType: String? = nil,
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        pixelWidth: Int = 0,
        pixelHeight: Int = 0,
        byteCount: Int = 0,
        sourceBundleID: String = "",
        sourceAppName: String = "",
        isPinned: Bool = false,
        customName: String = "",
        useCount: Int = 0,
        contentHash: String? = nil
    ) {
        self.date = date
        self.kindRaw = kind.rawValue
        self.text = text
        self.richData = richData
        self.richTypeRaw = richType
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteCount = byteCount
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
        self.isPinned = isPinned
        self.customName = customName
        self.useCount = useCount
        self.contentHash = contentHash ?? Clip.hash(kind: kind, text: text, imageData: imageData)
    }
}

extension Clip {
    var kind: ClipKind {
        get { ClipKind(rawValue: kindRaw) ?? .plainText }
        set { kindRaw = newValue.rawValue }
    }

    /// The number of characters that a menu row shows.
    static let titleLimit = 60

    /// The title of the row in the menu and in the history window.
    var title: String {
        let name = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }

        if kind == .image {
            let size = ImageSupport.sizeText(width: pixelWidth, height: pixelHeight)
            return String(localized: "Image \(size)", comment: "The title of an image clip")
        }

        return Self.summary(of: text)
    }

    /// The first line of the text, without the extra space, cut to the limit.
    static func summary(of text: String) -> String {
        let flat = text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var collapsed = flat
        while collapsed.contains("  ") {
            collapsed = collapsed.replacingOccurrences(of: "  ", with: " ")
        }

        if collapsed.isEmpty { return String(localized: "(empty)") }
        if collapsed.count <= titleLimit { return collapsed }

        return String(collapsed.prefix(titleLimit)) + "…"
    }

    /// `Text · 1.2 KB · Safari`, the line under the title in the history window.
    var detail: String {
        var parts = [kind.label]

        if kind == .image {
            parts.append(ImageSupport.sizeText(width: pixelWidth, height: pixelHeight))
        } else {
            parts.append(String(localized: "\(text.count) characters"))
        }

        parts.append(Self.byteText(byteCount))

        if !sourceAppName.isEmpty {
            parts.append(sourceAppName)
        }
        if useCount > 0 {
            parts.append(String(localized: "used \(useCount)×"))
        }

        return parts.joined(separator: " · ")
    }

    static func byteText(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }

    /// The SHA-256 of the content.
    ///
    /// The hash reads the plain text of a text clip, so the same words with two
    /// different fonts count as one clip. It reads the picture of an image clip.
    static func hash(kind: ClipKind, text: String, imageData: Data?) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(kind == .image ? "image".utf8 : "text".utf8))

        if kind == .image, let imageData {
            hasher.update(data: imageData)
        } else {
            hasher.update(data: Data(text.utf8))
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
