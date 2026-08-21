import Foundation

/// The characters that carry no visible mark.
///
/// A copy from a web page or from a chat window often brings them. Some are
/// harmless leftovers of the layout. Some carry information: the Unicode tags
/// block, `U+E0000` to `U+E007F`, holds one hidden letter for each ASCII letter,
/// and a text generator can write a whole message there. That block is the
/// watermark that this app removes.
enum InvisibleCharacters {
    /// Removed without a condition.
    ///
    /// The zero width joiner, `U+200D`, is **not** in this set. It joins the
    /// parts of an emoji, so a blind removal breaks 👨‍👩‍👧 into three people.
    /// `remove(from:)` handles it separately.
    static let removed: Set<Unicode.Scalar> = {
        var scalars: Set<Unicode.Scalar> = [
            "\u{00AD}", // Soft hyphen.
            "\u{061C}", // Arabic letter mark.
            "\u{180E}", // Mongolian vowel separator.
            "\u{200B}", // Zero width space.
            "\u{200C}", // Zero width non-joiner.
            "\u{200E}", // Left-to-right mark.
            "\u{200F}", // Right-to-left mark.
            "\u{2060}", // Word joiner.
            "\u{2061}", // Function application.
            "\u{2062}", // Invisible times.
            "\u{2063}", // Invisible separator.
            "\u{2064}", // Invisible plus.
            "\u{FEFF}", // Byte order mark.
        ]

        // The bidirectional format characters. They reorder the text and a
        // reader cannot see them, so a copied string can lie about its content.
        for value in 0x202A ... 0x202E { scalars.insert(Unicode.Scalar(value)!) }
        for value in 0x2066 ... 0x2069 { scalars.insert(Unicode.Scalar(value)!) }

        // The musical notation format characters.
        for value in 0x1D173 ... 0x1D17A { scalars.insert(Unicode.Scalar(value)!) }

        // The Unicode tags block: the hidden text of a watermark.
        for value in 0xE0000 ... 0xE007F { scalars.insert(Unicode.Scalar(value)!) }

        return scalars
    }()

    /// A space that is not the ordinary space. It becomes an ordinary space,
    /// because a search and a comparison fail on it.
    static let replacedSpaces: Set<Unicode.Scalar> = [
        "\u{00A0}", // No-break space.
        "\u{2000}", "\u{2001}", "\u{2002}", "\u{2003}", "\u{2004}",
        "\u{2005}", "\u{2006}", "\u{2007}", "\u{2008}", "\u{2009}",
        "\u{200A}", // The en quad to the hair space.
        "\u{202F}", // Narrow no-break space.
        "\u{205F}", // Medium mathematical space.
        "\u{3000}", // Ideographic space.
    ]

    /// The zero width joiner.
    private static let zeroWidthJoiner: Unicode.Scalar = "\u{200D}"

    /// Removes the invisible characters and replaces the special spaces.
    static func remove(from text: String) -> String {
        var result = String.UnicodeScalarView()
        let scalars = Array(text.unicodeScalars)

        for (index, scalar) in scalars.enumerated() {
            if removed.contains(scalar) { continue }

            if replacedSpaces.contains(scalar) {
                result.append(" ")
                continue
            }

            if scalar == zeroWidthJoiner {
                // Keep the joiner only between two emoji. Everywhere else it is
                // a hidden character.
                let previous = index > 0 ? scalars[index - 1] : nil
                let next = index + 1 < scalars.count ? scalars[index + 1] : nil

                if isEmoji(previous), isEmoji(next) {
                    result.append(scalar)
                }
                continue
            }

            result.append(scalar)
        }

        return String(result)
    }

    /// `true` when the scalar is part of an emoji. A variation selector counts,
    /// because it always follows the emoji that it changes.
    private static func isEmoji(_ scalar: Unicode.Scalar?) -> Bool {
        guard let scalar else { return false }

        if (0xFE00 ... 0xFE0F).contains(scalar.value) { return true }
        if (0x1F3FB ... 0x1F3FF).contains(scalar.value) { return true } // Skin tones.

        return scalar.properties.isEmoji && scalar.value > 0x203C
    }
}
