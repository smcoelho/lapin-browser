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
    @Published var enableICloudSync: Bool = false

    // Runtime-only, refreshed from the active browser on launch
    @Published var availableProfiles: [BrowserProfile] = []
    @Published var availableBrowsers: [Browser] = []

    let settingsURL: URL
    let iCloudURL: URL

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
        let iCloudBase = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs/LapinBrowser")
        iCloudURL = iCloudBase.appendingPathComponent("settings.json")
        load()
    }

    private func load() {
        let localData = try? Data(contentsOf: settingsURL)
        let cloudData = loadFromICloud()
        let data: Data?
        if let local = localData, let cloud = cloudData {
            let localDate = modDate(settingsURL)
            let cloudDate = modDate(iCloudURL)
            data = (cloudDate ?? .distantPast) > (localDate ?? .distantPast) ? cloud : local
        } else {
            data = cloudData ?? localData
        }
        guard let data,
              let decoded = try? JSONDecoder().decode(PersistedSettings.self, from: data) else { return }
        rules = decoded.rules
        defaultProfileID = decoded.defaultProfileID
        activeBrowserID = decoded.activeBrowserID
        launchAtLogin = decoded.launchAtLogin
        enableICloudSync = decoded.enableICloudSync
    }

    private func loadFromICloud() -> Data? {
        guard enableICloudSync else { return nil }
        if FileManager.default.fileExists(atPath: iCloudURL.path) {
            return try? Data(contentsOf: iCloudURL)
        }
        let placeholder = iCloudURL.deletingLastPathComponent()
            .appendingPathComponent("." + iCloudURL.lastPathComponent + ".icloud")
        if FileManager.default.fileExists(atPath: placeholder.path) {
            try? FileManager.default.startDownloadingUbiquitousItem(at: iCloudURL)
            logger.info("iCloud settings not yet downloaded; triggered download")
        }
        return nil
    }

    private func modDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
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
            launchAtLogin: launchAtLogin,
            enableICloudSync: enableICloudSync
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(persisted)
            try data.write(to: settingsURL)
            if enableICloudSync {
                writeToICloud(data)
            }
        } catch {
            logger.error("Failed to save settings: \(error)")
        }
    }

    private func writeToICloud(_ data: Data) {
        let dir = iCloudURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: iCloudURL)
        } catch {
            logger.warning("iCloud write failed (iCloud Drive may be unavailable): \(error)")
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
        var enableICloudSync: Bool = false
    }
}
