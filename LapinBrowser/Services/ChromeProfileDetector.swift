import Foundation
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "BrowserProfileDetector")

struct BrowserProfileDetector {
    static func detect(for browser: Browser) -> [BrowserProfile] {
        let localStatePath = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(browser.localStatePath)

        guard let data = try? Data(contentsOf: localStatePath) else {
            logger.warning("Local State not found at \(localStatePath.path)")
            return []
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: Any] else {
            logger.error("Failed to parse Local State JSON structure for \(browser.name)")
            return []
        }

        return infoCache.compactMap { (directoryName, value) -> BrowserProfile? in
            guard let info = value as? [String: Any] else { return nil }
            let displayName = info["name"] as? String ?? directoryName
            let email = info["user_name"] as? String ?? ""
            let gaiaName = info["gaia_name"] as? String ?? ""
            return BrowserProfile(
                id: directoryName,
                directoryName: directoryName,
                displayName: displayName,
                email: email,
                gaiaName: gaiaName
            )
        }
        .sorted { $0.directoryName < $1.directoryName }
    }
}
