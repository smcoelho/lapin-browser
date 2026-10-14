import XCTest
@testable import LapinBrowser

final class AppSettingsTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Backward compatibility

    func testDecodesSettingsWithoutActiveBrowserOrLaunchAtLogin() throws {
        // v1.0 settings files predate activeBrowserID and launchAtLogin.
        let json = #"""
        {
          "defaultProfileID": "Profile 1",
          "rules": [
            {
              "id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF",
              "isEnabled": true,
              "label": "",
              "pattern": "*.apple.com",
              "profileID": "Profile 2"
            }
          ]
        }
        """#
        let decoded = try JSONDecoder().decode(
            AppSettings.PersistedSettings.self, from: Data(json.utf8)
        )
        XCTAssertEqual(decoded.rules.count, 1)
        XCTAssertEqual(decoded.rules.first?.pattern, "*.apple.com")
        XCTAssertEqual(decoded.defaultProfileID, "Profile 1")
        XCTAssertEqual(decoded.activeBrowserID, Browser.googleChrome.id)
        XCTAssertFalse(decoded.launchAtLogin)
    }

    // MARK: - Unreadable settings are preserved

    func testUnreadableSettingsFileIsMovedAsideNotLost() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        let garbage = Data("{ not json".utf8)
        try garbage.write(to: url)

        let result = AppSettings.readPersisted(at: url)

        XCTAssertNil(result)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let backups = try FileManager.default.contentsOfDirectory(atPath: tempDir.path)
            .filter { $0.hasPrefix("settings.json.unreadable") }
        XCTAssertEqual(backups.count, 1)
        let backup = try XCTUnwrap(backups.first)
        let backupData = try Data(contentsOf: tempDir.appendingPathComponent(backup))
        XCTAssertEqual(backupData, garbage)
    }

    func testMissingSettingsFileReturnsNilWithoutBackup() throws {
        let url = tempDir.appendingPathComponent("settings.json")
        XCTAssertNil(AppSettings.readPersisted(at: url))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: tempDir.path).isEmpty)
    }
}
