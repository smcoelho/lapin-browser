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

    // Runtime-only, refreshed from all installed browsers on launch
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

    /// Reads settings from `url`. A file that exists but can't be decoded is moved aside
    /// (to `settings.json.unreadable-<timestamp>`) so the next `save()` doesn't destroy it.
    nonisolated static func readPersisted(at url: URL) -> PersistedSettings? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(PersistedSettings.self, from: data)
        } catch {
            logger.error("Failed to decode settings: \(error)")
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.deletingLastPathComponent()
                .appendingPathComponent("\(url.lastPathComponent).unreadable-\(stamp)")
            do {
                try FileManager.default.moveItem(at: url, to: backup)
                logger.error("Moved unreadable settings to \(backup.path)")
            } catch {
                logger.error("Failed to move unreadable settings aside: \(error)")
            }
            return nil
        }
    }

    private func load() {
        guard let decoded = AppSettings.readPersisted(at: settingsURL) else { return }
        rules = decoded.rules
        defaultProfileID = decoded.defaultProfileID
        activeBrowserID = decoded.activeBrowserID
        launchAtLogin = decoded.launchAtLogin
    }

    func save() {
        let enrichedRules = rules.map { rule -> URLRule in
            let profile: BrowserProfile?
            if let bid = rule.browserID {
                profile = availableProfiles.first { $0.id == rule.profileID && $0.browserID == bid }
            } else {
                profile = availableProfiles.first { $0.id == rule.profileID }
            }
            guard let profile else { return rule }
            return rule.enriched(with: profile)
        }
        let persisted = PersistedSettings(
            rules: enrichedRules,
            defaultProfileID: defaultProfileID,
            activeBrowserID: activeBrowserID,
            launchAtLogin: launchAtLogin
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(persisted)
            try data.write(to: settingsURL)
        } catch {
            logger.error("Failed to save settings: \(error)")
        }
    }

    func resolveProfileIDs() {
        let before = rules
        rules = rules.map { rule in
            let candidateProfiles: [BrowserProfile]
            if let bid = rule.browserID {
                candidateProfiles = availableProfiles.filter { $0.browserID == bid }
            } else {
                candidateProfiles = availableProfiles
            }
            guard !candidateProfiles.contains(where: { $0.id == rule.profileID }) else { return rule }
            guard let match = candidateProfiles.first(where: { profile in
                (rule.profileEmail != nil       && profile.email == rule.profileEmail) ||
                (rule.profileGaiaName != nil    && profile.gaiaName == rule.profileGaiaName) ||
                (rule.profileDisplayName != nil && profile.displayName == rule.profileDisplayName)
            }) else { return rule }
            var updated = rule
            updated.profileID = match.id
            return updated
        }
        if rules != before { save() }
    }

    struct PersistedSettings: Codable {
        var rules: [URLRule]
        var defaultProfileID: String
        var activeBrowserID: String
        var launchAtLogin: Bool

        init(rules: [URLRule], defaultProfileID: String, activeBrowserID: String, launchAtLogin: Bool) {
            self.rules = rules
            self.defaultProfileID = defaultProfileID
            self.activeBrowserID = activeBrowserID
            self.launchAtLogin = launchAtLogin
        }

        // Synthesized Decodable ignores property defaults, so keys added after v1.0
        // must be decoded with decodeIfPresent to keep older settings files readable.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            rules = try c.decodeIfPresent([URLRule].self, forKey: .rules) ?? []
            defaultProfileID = try c.decodeIfPresent(String.self, forKey: .defaultProfileID) ?? ""
            activeBrowserID = try c.decodeIfPresent(String.self, forKey: .activeBrowserID) ?? Browser.googleChrome.id
            launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        }
    }
}
