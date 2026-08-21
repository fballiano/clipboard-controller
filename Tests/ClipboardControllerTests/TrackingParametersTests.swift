import Foundation
import Testing
@testable import ClipboardController

@Suite("Tracking parameters")
struct TrackingParametersTests {
    private func clean(_ url: String) -> String {
        Sanitizer.removeTrackingParameters(from: url)
    }

    // MARK: - The global table

    @Test("A utm parameter goes")
    func removesUTM() {
        #expect(clean("https://example.com/page?utm_source=news&id=7")
            == "https://example.com/page?id=7")
    }

    @Test("The question mark goes with the last parameter")
    func removesQuestionMark() {
        #expect(clean("https://example.com/page?utm_source=news")
            == "https://example.com/page")
    }

    @Test("The known identifiers of the advertisement networks go")
    func removesAdIdentifiers() {
        #expect(clean("https://example.com/?fbclid=abc") == "https://example.com/")
        #expect(clean("https://example.com/?gclid=abc") == "https://example.com/")
        #expect(clean("https://example.com/?msclkid=abc") == "https://example.com/")
        #expect(clean("https://example.com/?mc_eid=abc") == "https://example.com/")
    }

    @Test("A real parameter stays")
    func keepsRealParameters() {
        let url = "https://example.com/search?q=swift&page=2"
        #expect(clean(url) == url)
    }

    @Test("A URL without a question mark does not change")
    func keepsPlainURL() {
        let url = "https://example.com/page"
        #expect(clean(url) == url)
    }

    // MARK: - The host rules

    @Test("A short name is a tracker only on its own site")
    func hostRules() {
        #expect(clean("https://x.com/user/status/1?s=20&t=abc")
            == "https://x.com/user/status/1")

        // The same names on another site are a search and a time.
        let other = "https://example.com/find?s=20&t=abc"
        #expect(clean(other) == other)
    }

    @Test("A subdomain follows the rule of its parent")
    func matchesSubdomain() {
        #expect(clean("https://mobile.x.com/user/status/1?s=20")
            == "https://mobile.x.com/user/status/1")
    }

    @Test("The parameters of TikTok, YouTube and Amazon go")
    func siteRules() {
        #expect(clean("https://www.tiktok.com/@user/video/1?_t=abc&_r=1")
            == "https://www.tiktok.com/@user/video/1")
        #expect(clean("https://youtu.be/abcdefg?si=xyz")
            == "https://youtu.be/abcdefg")
        #expect(clean("https://www.amazon.com/dp/B01?ref_=abc&psc=1")
            == "https://www.amazon.com/dp/B01")
    }

    // MARK: - Inside a text

    @Test("A URL inside a sentence is cleaned, the words stay")
    func insideText() {
        let text = "Look at https://example.com/a?utm_medium=email now."
        #expect(clean(text) == "Look at https://example.com/a now.")
    }

    @Test("Two URLs in one text are both cleaned")
    func twoURLs() {
        let text = "https://a.example/?utm_source=1 and https://b.example/?gclid=2"
        #expect(clean(text) == "https://a.example/ and https://b.example/")
    }

    // MARK: - The table itself

    @Test("The test of one name answers for the host and for the world")
    func isTracking() {
        #expect(TrackingParameters.isTracking(name: "utm_source", host: nil))
        #expect(TrackingParameters.isTracking(name: "UTM_SOURCE", host: nil))
        #expect(!TrackingParameters.isTracking(name: "s", host: "example.com"))
        #expect(TrackingParameters.isTracking(name: "s", host: "x.com"))
        #expect(!TrackingParameters.isTracking(name: "q", host: "x.com"))
    }
}
