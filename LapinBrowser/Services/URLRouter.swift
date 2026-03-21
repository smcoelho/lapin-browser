import Foundation
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "URLRouter")

struct URLRouter {
    static let shared = URLRouter()
    private init() {}

    @MainActor
    func route(_ url: URL) {
        let settings = AppSettings.shared
        let profileID = URLRouter.matchedProfileID(for: url, rules: settings.rules)
            ?? settings.defaultProfileID

        guard !profileID.isEmpty else {
            logger.warning("No default profile configured — skipping \(url.absoluteString)")
            return
        }

        guard let profile = settings.availableProfiles.first(where: { $0.id == profileID }) else {
            logger.warning("Profile '\(profileID)' not found in available profiles — skipping \(url.absoluteString)")
            return
        }

        ChromeLauncher.open(url, in: profile)
    }

    // Internal so URLRouterTests can exercise matching logic directly.
    // Patterns with no `/` are matched against the URL host only.
    // Patterns with `/` are matched against the full absoluteString (including scheme).
    static func matchedProfileID(for url: URL, rules: [URLRule]) -> String? {
        for rule in rules where rule.isEnabled {
            let subject: String
            if rule.pattern.contains("/") {
                // Normalize: add trailing slash when the URL has no path, so that
                // "https://www.instagram.com/" matches both https://www.instagram.com
                // and https://www.instagram.com/ as received from the OS.
                var str = url.absoluteString
                if url.path.isEmpty && !str.hasSuffix("/") { str += "/" }
                subject = str
            } else {
                subject = url.host ?? ""
            }
            if fnmatch(rule.pattern, subject, FNM_CASEFOLD) == 0 {
                return rule.profileID
            }
        }
        return nil
    }
}
