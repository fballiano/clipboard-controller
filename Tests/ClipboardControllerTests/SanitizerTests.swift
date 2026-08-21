import Foundation
import Testing
@testable import ClipboardController

@Suite("Sanitizer")
struct SanitizerTests {
    private func sanitizer(_ options: Sanitizer.Options) -> Sanitizer {
        Sanitizer(options: options)
    }

    @Test("No rule changes nothing")
    func noRules() {
        let text = "  Hello \u{200B}“world”  \r\n\r\n\r\n • one  "
        #expect(sanitizer(.none).clean(text) == text)
    }

    // MARK: - The invisible characters

    @Test("A zero width character goes")
    func removesZeroWidth() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)

        #expect(sanitizer(options).clean("a\u{200B}b") == "ab")
        #expect(sanitizer(options).clean("a\u{FEFF}b") == "ab")
        #expect(sanitizer(options).clean("a\u{00AD}b") == "ab")
        #expect(sanitizer(options).clean("a\u{2060}b") == "ab")
    }

    @Test("The hidden text of a watermark goes")
    func removesTagsBlock() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)
        let watermark = "\u{E0041}\u{E0049}"

        #expect(sanitizer(options).clean("Hello\(watermark) world") == "Hello world")
    }

    @Test("A bidirectional mark goes")
    func removesBidiMarks() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)

        #expect(sanitizer(options).clean("a\u{202E}b\u{202C}") == "ab")
    }

    @Test("A special space becomes an ordinary space")
    func replacesSpaces() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)

        #expect(sanitizer(options).clean("a\u{00A0}b") == "a b")
        #expect(sanitizer(options).clean("a\u{202F}b") == "a b")
    }

    @Test("An emoji keeps its joiner")
    func keepsEmojiJoiner() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)
        let family = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}"

        #expect(sanitizer(options).clean(family) == family)
    }

    @Test("A joiner between two letters goes")
    func removesTextJoiner() {
        let options = Sanitizer.Options(removeInvisibleCharacters: true)

        #expect(sanitizer(options).clean("a\u{200D}b") == "ab")
    }

    // MARK: - The quotes

    @Test("A curly quote becomes a straight quote")
    func normalizesQuotes() {
        let options = Sanitizer.Options(normalizeQuotes: true)

        #expect(sanitizer(options).clean("\u{201C}Hello\u{201D}") == "\"Hello\"")
        #expect(sanitizer(options).clean("it\u{2019}s") == "it's")
        #expect(sanitizer(options).clean("wait\u{2026}") == "wait...")
    }

    // MARK: - The ends of the lines

    @Test("Every end of line becomes a line feed")
    func normalizesNewlines() {
        let options = Sanitizer.Options(normalizeNewlines: true)

        #expect(sanitizer(options).clean("a\r\nb\rc") == "a\nb\nc")
    }

    @Test("Two or more empty lines become one")
    func collapsesEmptyLines() {
        let options = Sanitizer.Options(normalizeNewlines: true)

        #expect(sanitizer(options).clean("a\n\n\n\n\nb") == "a\n\nb")
    }

    // MARK: - The lists

    @Test("A bullet becomes a hyphen")
    func normalizesLists() {
        let options = Sanitizer.Options(normalizeLists: true)

        #expect(sanitizer(options).clean("\u{2022} one\n\u{2022} two") == "- one\n- two")
        #expect(sanitizer(options).clean("\u{2013} one") == "- one")
    }

    @Test("The indentation of a list inside a list stays")
    func keepsIndentation() {
        let options = Sanitizer.Options(normalizeLists: true)

        #expect(sanitizer(options).clean("    \u{2022} one") == "    - one")
    }

    @Test("A star stays a star, because Markdown uses it")
    func keepsMarkdownStar() {
        let options = Sanitizer.Options(normalizeLists: true)

        #expect(sanitizer(options).clean("* one") == "* one")
    }

    @Test("A bullet without a space is not a list")
    func needsSpaceAfterBullet() {
        let options = Sanitizer.Options(normalizeLists: true)

        #expect(sanitizer(options).clean("\u{2022}one") == "\u{2022}one")
    }

    // MARK: - The whitespace

    @Test("The space at the start, at the end and at the end of a line goes")
    func trimsWhitespace() {
        let options = Sanitizer.Options(trimWhitespace: true)

        #expect(sanitizer(options).clean("  hello  ") == "hello")
        #expect(sanitizer(options).clean("a   \nb") == "a\nb")
        #expect(sanitizer(options).clean("\n\nhello\n\n") == "hello")
    }

    // MARK: - Together

    @Test("Every rule runs in one pass")
    func everyRule() {
        let text = "  \u{201C}Read\u{201D}\u{200B}\r\n\r\n\r\n\u{2022} https://example.com/?utm_source=x&id=7  "
        let result = sanitizer(.all).clean(text)

        #expect(result == "\"Read\"\n\n- https://example.com/?id=7")
    }

    @Test("An active option set knows that it is active")
    func isActive() {
        #expect(!Sanitizer.Options.none.isActive)
        #expect(Sanitizer.Options.all.isActive)
        #expect(Sanitizer.Options(trimWhitespace: true).isActive)
    }
}
