import Foundation

/// Cleans a piece of text.
///
/// The type is pure: it holds no state, it touches no system, and it uses no
/// AppKit. Every rule of the cleaner lives here, so the tests can read each rule
/// without a clipboard and without a window.
struct Sanitizer: Sendable {
    /// One switch for each rule. The settings window writes these values.
    struct Options: Sendable, Equatable {
        var removeInvisibleCharacters: Bool
        var normalizeQuotes: Bool
        var normalizeNewlines: Bool
        var normalizeLists: Bool
        var trimWhitespace: Bool
        var removeTrackingParameters: Bool

        init(
            removeInvisibleCharacters: Bool = false,
            normalizeQuotes: Bool = false,
            normalizeNewlines: Bool = false,
            normalizeLists: Bool = false,
            trimWhitespace: Bool = false,
            removeTrackingParameters: Bool = false
        ) {
            self.removeInvisibleCharacters = removeInvisibleCharacters
            self.normalizeQuotes = normalizeQuotes
            self.normalizeNewlines = normalizeNewlines
            self.normalizeLists = normalizeLists
            self.trimWhitespace = trimWhitespace
            self.removeTrackingParameters = removeTrackingParameters
        }

        /// No rule is on. The text stays as it is.
        static let none = Options()

        /// Every rule is on.
        static let all = Options(
            removeInvisibleCharacters: true,
            normalizeQuotes: true,
            normalizeNewlines: true,
            normalizeLists: true,
            trimWhitespace: true,
            removeTrackingParameters: true
        )

        /// `true` when at least one rule is on.
        var isActive: Bool { self != .none }
    }

    let options: Options

    init(options: Options = .all) {
        self.options = options
    }

    /// Applies every rule that is on.
    ///
    /// The order matters. The newlines come first, because the list rule reads
    /// the start of a line. The trim comes last, because the other rules can
    /// leave a space at the end.
    func clean(_ text: String) -> String {
        var result = text

        if options.removeInvisibleCharacters {
            result = InvisibleCharacters.remove(from: result)
        }
        if options.normalizeNewlines {
            result = Self.normalizeNewlines(result)
        }
        if options.normalizeLists {
            result = Self.normalizeLists(result)
        }
        if options.normalizeQuotes {
            result = Self.normalizeQuotes(result)
        }
        if options.removeTrackingParameters {
            result = Self.removeTrackingParameters(from: result)
        }
        if options.trimWhitespace {
            result = Self.trimWhitespace(result)
        }

        return result
    }

    // MARK: - The rules

    /// Every end of line becomes a line feed. Two or more empty lines become
    /// one empty line.
    static func normalizeNewlines(_ text: String) -> String {
        var result = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n\n")

        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result
    }

    /// A curly quote becomes a straight quote. The ellipsis becomes three
    /// points.
    static func normalizeQuotes(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.count)

        for character in text {
            switch character {
            case "\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}":
                result.append("\"")
            case "\u{2018}", "\u{2019}", "\u{201A}", "\u{201B}", "\u{02BC}":
                result.append("'")
            case "\u{2026}":
                result.append("...")
            default:
                result.append(character)
            }
        }

        return result
    }

    /// A bullet at the start of a line becomes a hyphen and a space.
    ///
    /// The indentation stays, so a list inside a list keeps its shape. A star is
    /// not a bullet here, because a star already writes a list in Markdown.
    static func normalizeLists(_ text: String) -> String {
        let bullets: Set<Character> = [
            "\u{2022}", // •
            "\u{25E6}", // ◦
            "\u{2023}", // ‣
            "\u{2043}", // ⁃
            "\u{2219}", // ∙
            "\u{00B7}", // ·
            "\u{25CF}", // ●
            "\u{25CB}", // ○
            "\u{25AA}", // ▪
            "\u{25AB}", // ▫
            "\u{2013}", // –
            "\u{2014}", // —
        ]

        let lines = text.components(separatedBy: "\n").map { line -> String in
            let indent = line.prefix { $0 == " " || $0 == "\t" }
            let rest = line.dropFirst(indent.count)

            guard let bullet = rest.first, bullets.contains(bullet) else { return line }

            let afterBullet = rest.dropFirst()
            guard let next = afterBullet.first, next == " " || next == "\t" else { return line }

            let content = afterBullet.drop { $0 == " " || $0 == "\t" }
            return "\(indent)- \(content)"
        }

        return lines.joined(separator: "\n")
    }

    /// Removes the space at the end of each line, and at the start and at the
    /// end of the whole text.
    static func trimWhitespace(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n").map { line in
            String(line.reversed().drop { $0 == " " || $0 == "\t" }.reversed())
        }

        return lines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - The trackers in a URL

    private static let linkDetector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    /// Finds every URL in the text and removes the tracking parameters of each
    /// one. The rest of the text does not change.
    static func removeTrackingParameters(from text: String) -> String {
        guard text.contains("?"), let detector = linkDetector else { return text }

        let string = text as NSString
        let matches = detector.matches(
            in: text,
            range: NSRange(location: 0, length: string.length)
        )
        guard !matches.isEmpty else { return text }

        // The pieces are joined in order, because a replacement inside a string
        // that is being read moves every index after it.
        var result = ""
        var position = 0

        for match in matches {
            let range = match.range
            result += string.substring(with: NSRange(
                location: position,
                length: range.location - position
            ))

            let raw = string.substring(with: range)
            result += cleanURL(raw, host: match.url?.host) ?? raw

            position = range.location + range.length
        }

        result += string.substring(from: position)

        return result
    }

    /// Removes the tracking parameters of one URL.
    /// - Parameters:
    ///   - raw: the URL as it stands in the text.
    ///   - host: the host that the detector found. A URL without a scheme, for
    ///     example `example.com/a?x=1`, has no host of its own.
    /// - Returns: the new URL, or `nil` when nothing changed.
    static func cleanURL(_ raw: String, host: String? = nil) -> String? {
        guard raw.contains("?"), var components = URLComponents(string: raw) else { return nil }

        // The percent encoded items keep the original spelling of the URL. The
        // decoded items would rewrite `+` and other characters, so a URL that
        // holds no tracker at all would still change.
        guard let items = components.percentEncodedQueryItems, !items.isEmpty else { return nil }

        let resolvedHost = components.host ?? host
        let kept = items.filter { item in
            let name = item.name.removingPercentEncoding ?? item.name
            return !TrackingParameters.isTracking(name: name, host: resolvedHost)
        }

        guard kept.count != items.count else { return nil }

        // `nil` removes the question mark as well.
        components.percentEncodedQueryItems = kept.isEmpty ? nil : kept

        return components.string
    }
}
