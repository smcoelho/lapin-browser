import Foundation

struct ChromeProfileDetector {
    static func detect() -> [ChromeProfile] {
        let localStatePath = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome/Local State")

        guard let data = try? Data(contentsOf: localStatePath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileSection = json["profile"] as? [String: Any],
              let infoCache = profileSection["info_cache"] as? [String: Any] else {
            return []
        }

        return infoCache.compactMap { (directoryName, value) -> ChromeProfile? in
            guard let info = value as? [String: Any] else { return nil }
            let displayName = info["name"] as? String ?? directoryName
            let email = info["user_name"] as? String ?? ""
            let gaiaName = info["gaia_name"] as? String ?? ""
            return ChromeProfile(
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
