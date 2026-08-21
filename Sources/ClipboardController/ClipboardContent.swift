import AppKit
import Foundation

/// What the app read from the clipboard, ready for the store.
struct ClipboardContent: Sendable, Equatable {
    var kind: ClipKind
    var text: String
    var richData: Data?
    var richType: String?
    var imageData: Data?
    var thumbnailData: Data?
    var pixelWidth: Int
    var pixelHeight: Int
    var byteCount: Int
    var sourceBundleID: String
    var sourceAppName: String

    init(
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
        sourceAppName: String = ""
    ) {
        self.kind = kind
        self.text = text
        self.richData = richData
        self.richType = richType
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.byteCount = byteCount
        self.sourceBundleID = sourceBundleID
        self.sourceAppName = sourceAppName
    }
}

/// The application that was in front when the content arrived.
struct ClipboardSource: Sendable, Equatable {
    var bundleID: String
    var name: String

    static let unknown = ClipboardSource(bundleID: "", name: "")
}

/// What the settings say at the moment of a change of the clipboard.
///
/// The monitor takes a copy of the settings at each change, so it never reads
/// `Preferences` itself. A test can therefore give any combination of settings
/// without a `UserDefaults` instance.
struct ClipboardPolicy: Sendable, Equatable {
    /// Store what the user copies.
    var recordClipboard = true

    /// Store nothing until the user turns the private mode off.
    var privateMode = false

    /// Clean each new content of the clipboard.
    var automaticCleaning = true

    /// Store the pictures as well as the text.
    var storeImages = true

    /// Throw the formatting away and keep the plain text.
    var removeFormatting = true

    /// Keep the links of the formatted text.
    var preserveLinks = false

    /// The rules of the text cleaner.
    var sanitizer = Sanitizer.Options.all

    /// Do not store anything that comes from these applications.
    var excludedRecordingApps: Set<String> = []

    /// Do not clean anything that comes from these applications.
    var excludedCleaningApps: Set<String> = []

    /// Do not store a text longer than this. `0` means no limit.
    var maxTextLength = 0

    /// Do not store a picture bigger than this, in bytes. `0` means no limit.
    var maxImageBytes = 0

    /// `true` when the cleaner has work to do.
    var cleansAnything: Bool { removeFormatting || sanitizer.isActive }
}
