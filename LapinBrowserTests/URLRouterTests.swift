import XCTest
@testable import LapinBrowser

final class URLRouterTests: XCTestCase {

    // MARK: - Host Pattern Tests

    func testHostPatternMatches() throws {
        let rules = [URLRule(pattern: "*.apple.com", profileID: "Profile 1")]
        let url = URL(string: "https://developer.apple.com/documentation")!
        XCTAssertEqual(URLRouter.matchedProfileID(for: url, rules: rules), "Profile 1")
    }

    func testHostPatternNoMatch() throws {
        let rules = [URLRule(pattern: "*.google.com", profileID: "Profile 1")]
        let url = URL(string: "https://developer.apple.com")!
        XCTAssertNil(URLRouter.matchedProfileID(for: url, rules: rules))
    }

    // MARK: - Full URL Pattern Tests
    // Patterns containing "/" are matched against url.absoluteString (including scheme).

    func testFullURLPatternMatches() throws {
        let rules = [URLRule(pattern: "https://blip.pt/*", profileID: "Profile 2")]
        let url = URL(string: "https://blip.pt/articles/123")!
        XCTAssertEqual(URLRouter.matchedProfileID(for: url, rules: rules), "Profile 2")
    }

    func testFullURLPatternNoMatch() throws {
        let rules = [URLRule(pattern: "https://blip.pt/*", profileID: "Profile 2")]
        let url = URL(string: "https://example.com/page")!
        XCTAssertNil(URLRouter.matchedProfileID(for: url, rules: rules))
    }

    // MARK: - Disabled Rule Tests

    func testDisabledRuleSkipped() throws {
        let rules = [
            URLRule(pattern: "*.apple.com", profileID: "Profile 1", isEnabled: false)
        ]
        let url = URL(string: "https://developer.apple.com/documentation")!
        XCTAssertNil(URLRouter.matchedProfileID(for: url, rules: rules))
    }

    func testDisabledRuleBeforeEnabledRuleContinuesToNext() throws {
        let rules = [
            URLRule(pattern: "*.apple.com", profileID: "Profile 1", isEnabled: false),
            URLRule(pattern: "*.apple.com", profileID: "Profile 2", isEnabled: true)
        ]
        let url = URL(string: "https://developer.apple.com")!
        XCTAssertEqual(URLRouter.matchedProfileID(for: url, rules: rules), "Profile 2")
    }

    // MARK: - Rule Priority Tests

    func testFirstMatchWins() throws {
        let rules = [
            URLRule(pattern: "*.apple.com", profileID: "Profile 1"),
            URLRule(pattern: "*.apple.com", profileID: "Profile 2")
        ]
        let url = URL(string: "https://developer.apple.com/documentation")!
        XCTAssertEqual(URLRouter.matchedProfileID(for: url, rules: rules), "Profile 1")
    }

    // MARK: - Empty and No-Match Tests

    func testEmptyRulesReturnsNil() throws {
        let rules: [URLRule] = []
        let url = URL(string: "https://developer.apple.com")!
        XCTAssertNil(URLRouter.matchedProfileID(for: url, rules: rules))
    }

    func testNoMatchReturnsNil() throws {
        let rules = [
            URLRule(pattern: "*.google.com", profileID: "Profile 1"),
            URLRule(pattern: "*.microsoft.com", profileID: "Profile 2")
        ]
        let url = URL(string: "https://example.com")!
        XCTAssertNil(URLRouter.matchedProfileID(for: url, rules: rules))
    }

    // MARK: - Case Insensitivity Tests

    func testCaseInsensitiveMatch() throws {
        let rules = [URLRule(pattern: "*.APPLE.COM", profileID: "Profile 1")]
        let url = URL(string: "https://developer.apple.com")!
        XCTAssertEqual(URLRouter.matchedProfileID(for: url, rules: rules), "Profile 1")
    }
}
