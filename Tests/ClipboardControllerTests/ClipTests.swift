import Foundation
import Testing
@testable import ClipboardController

@MainActor
@Suite("Clip")
struct ClipTests {
    @Test("The title is the first line of the text")
    func titleFromText() {
        let clip = Clip(kind: .plainText, text: "first line\nsecond line")

        #expect(clip.title == "first line second line")
    }

    @Test("A long text is cut")
    func cutsLongText() {
        let clip = Clip(kind: .plainText, text: String(repeating: "a", count: 200))

        #expect(clip.title.count == Clip.titleLimit + 1) // The last character is the ellipsis.
        #expect(clip.title.hasSuffix("…"))
    }

    @Test("The extra space goes")
    func collapsesSpace() {
        #expect(Clip.summary(of: "  a     b  ") == "a b")
    }

    @Test("A text of spaces only says that it is empty")
    func emptyText() {
        // The tests load into the real app, so the app answers in the language
        // of the user. The test therefore asks for the translated words.
        #expect(Clip.summary(of: "   \n  ") == String(localized: "(empty)"))
    }

    @Test("A name from the user wins")
    func customName() {
        let clip = Clip(kind: .plainText, text: "some text", customName: "My address")

        #expect(clip.title == "My address")
    }

    @Test("An image says its size")
    func imageTitle() {
        let clip = Clip(kind: .image, text: "", pixelWidth: 1280, pixelHeight: 720)

        // The word before the size follows the language of the user.
        #expect(clip.title.hasSuffix("1280 × 720"))
    }

    @Test("The same words give the same hash, other words give another")
    func hashing() {
        let first = Clip.hash(kind: .plainText, text: "hello", imageData: nil)
        let second = Clip.hash(kind: .plainText, text: "hello", imageData: nil)
        let third = Clip.hash(kind: .plainText, text: "world", imageData: nil)

        #expect(first == second)
        #expect(first != third)
    }

    @Test("Formatted text and plain text with the same words are one clip")
    func hashIgnoresFormatting() {
        let plain = Clip.hash(kind: .plainText, text: "hello", imageData: nil)
        let rich = Clip.hash(kind: .richText, text: "hello", imageData: nil)

        #expect(plain == rich)
    }
}
