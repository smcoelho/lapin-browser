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

    private func load() {
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? JSONDecoder().decode(PersistedSettings.self, from: data) else { return }
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

    private struct PersistedSettings: Codable {
        var rules: [URLRule]
        var defaultProfileID: String
        var activeBrowserID: String = Browser.googleChrome.id
        var launchAtLogin: Bool = false
    }
}
