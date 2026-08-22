import Foundation
import Testing

@testable import ClipboardController

/// The translations live in `Resources/Localizable.xcstrings`. The build turns
/// the catalog into one `.strings` file, and one `.stringsdict` file for the
/// plural forms, for each language.
///
/// A translation that is missing does not break the build: the app falls back to
/// English. The suite therefore compares the languages with each other.
///
/// English is not the measure. The key of the catalog is the English text, so
/// the build writes no English row for it, and `en.lproj` is nearly empty.
@Suite struct Localization {
    /// The languages of the catalog. English is the source language.
    static let languages = ["de", "es", "fr", "it", "pt-BR"]

    /// The size of the catalog at the last change. The test asks only for the
    /// order of magnitude, so a new string needs no change here.
    static let leastKeys = 80

    /// Every key of a language, from the two compiled files together. A plural
    /// form lives in the `.stringsdict` file and not in the `.strings` file, so
    /// the two tables must be read as one.
    static func keys(of language: String) throws -> Set<String> {
        let path = try #require(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "no \(language).lproj in the application bundle"
        )
        let bundle = try #require(Bundle(path: path))

        var keys = Set<String>()

        for name in ["Localizable.strings", "Localizable.stringsdict"] {
            let url = bundle.bundleURL.appending(path: name)
            guard let table = NSDictionary(contentsOf: url) as? [String: Any] else { continue }
            keys.formUnion(table.keys)
        }

        return keys
    }

    /// Every key that any language holds.
    static func allKeys() throws -> Set<String> {
        try languages.reduce(into: Set<String>()) { keys, language in
            keys.formUnion(try Localization.keys(of: language))
        }
    }

    @Test("Every language carries the whole catalog", arguments: Localization.languages)
    func languageTranslatesEveryString(language: String) throws {
        let missing = try Localization.allKeys()
            .subtracting(try Localization.keys(of: language))
            .sorted()

        #expect(missing.isEmpty, "\(language) does not translate: \(missing.joined(separator: ", "))")
    }

    @Test("The catalog holds the strings of the app")
    func catalogIsNotEmpty() throws {
        let count = try Localization.allKeys().count

        #expect(count >= Localization.leastKeys)
    }
}
