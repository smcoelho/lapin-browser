import XCTest
@testable import LapinBrowser

final class BrowserProfileDetectorTests: XCTestCase {

    func testNoProfileBrowserReturnsSingleSyntheticDefault() {
        let profiles = BrowserProfileDetector.detect(for: .safari)
        XCTAssertEqual(profiles.count, 1)
    }

    func testSyntheticProfileHasExpectedFields() throws {
        let profile = try XCTUnwrap(BrowserProfileDetector.detect(for: .safari).first)
        XCTAssertEqual(profile.id, "default")
        XCTAssertEqual(profile.directoryName, "default")
        XCTAssertEqual(profile.displayName, "Default")
        XCTAssertEqual(profile.email, "")
        XCTAssertEqual(profile.gaiaName, "")
        XCTAssertEqual(profile.browserID, "com.apple.Safari")
    }
}
