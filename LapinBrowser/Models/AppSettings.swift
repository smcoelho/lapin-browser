import Foundation
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "AppSettings")

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var rules: [URLRule] = []
    @Published var defaultProfileID: String = ""
    @Published var activeBrowserID: String = Browser.googleChrome.id
    @Published var launchAtLogin: Bool = false

    // Runtime-only, refreshed from the active browser on launch
    @Published var availableProfiles: [BrowserProfile] = []
    @Published var availableBrowsers: [Browser] = []

    let settingsURL: URL

    private init() {
        let appSupport: URL
        if let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            appSupport = url
        } else {
            appSupport = FileManager.default.temporaryDirectory
            logger.error("Could not find Application Support directory; using temp dir")
        }
        let dir = appSupport.appendingPathComponent("pt.lapin.browser")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create settings directory: \(error)")
        }
        settingsURL = dir.appendingPathComponent("settings.json")
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? JSONDecoder().decode(PersistedSettings.self, from: data) else { return }
        rules = decoded.rules
        defaultProfileID = decoded.defaultProfileID
        activeBrowserID = decoded.activeBrowserID
        launchAtLogin = decoded.launchAtLogin
    }

    func save() {
        let persisted = PersistedSettings(rules: rules, defaultProfileID: defaultProfileID, activeBrowserID: activeBrowserID, launchAtLogin: launchAtLogin)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(persisted)
            try data.write(to: settingsURL)
        } catch {
            logger.error("Failed to save settings: \(error)")
        }
    }

    private struct PersistedSettings: Codable {
        var rules: [URLRule]
        var defaultProfileID: String
        var activeBrowserID: String = Browser.googleChrome.id
        var launchAtLogin: Bool = false
    }
}
