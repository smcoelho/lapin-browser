import Foundation

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var rules: [URLRule] = []
    @Published var defaultProfileID: String = ""

    // Runtime-only, refreshed from Chrome on launch
    @Published var availableProfiles: [ChromeProfile] = []

    private let settingsURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("pt.lapin.browser")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        settingsURL = dir.appendingPathComponent("settings.json")
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? JSONDecoder().decode(PersistedSettings.self, from: data) else { return }
        rules = decoded.rules
        defaultProfileID = decoded.defaultProfileID
    }

    func save() {
        let persisted = PersistedSettings(rules: rules, defaultProfileID: defaultProfileID)
        guard let data = try? JSONEncoder().encode(persisted) else { return }
        try? data.write(to: settingsURL)
    }

    private struct PersistedSettings: Codable {
        var rules: [URLRule]
        var defaultProfileID: String
    }
}
