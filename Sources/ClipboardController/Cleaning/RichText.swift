import AppKit
import Foundation

/// Turns the rich text of the clipboard into plain text, and builds the
/// "links only" form.
///
/// The HTML reader of `NSAttributedString` uses WebKit, so every call must run
/// on the main thread.
@MainActor
enum RichText {
    /// Reads RTF, RTFD or HTML.
    static func attributed(from data: Data, type: NSPasteboard.PasteboardType) -> NSAttributedString? {
        let documentType: NSAttributedString.DocumentType
        switch type {
        case .rtf: documentType = .rtf
        case .rtfd: documentType = .rtfd
        case .html: documentType = .html
        default: return nil
        }

        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: documentType,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        )
    }

    /// Builds RTF that holds the text and the links, and nothing else.
    ///
    /// This is the "preserve links" setting. A link carries information that the
    /// plain text loses, so the app keeps the link attribute and throws every
    /// other attribute away: the font, the colour, the size and the paragraph
    /// style.
    static func linksOnly(from attributed: NSAttributedString) -> Data? {
        let result = NSMutableAttributedString(string: attributed.string)

        attributed.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: attributed.length)
        ) { value, range, _ in
            guard let value else { return }
            result.addAttribute(.link, value: value, range: range)
        }

        return result.rtf(
            from: NSRange(location: 0, length: result.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }

    /// `true` when the rich text holds at least one link.
    static func hasLink(_ attributed: NSAttributedString) -> Bool {
        var found = false

        attributed.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: attributed.length)
        ) { value, _, stop in
            if value != nil {
                found = true
                stop.pointee = true
            }
        }

        return found
    }
}
