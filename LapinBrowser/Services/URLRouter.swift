import Foundation
import Darwin
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "URLRouter")

struct URLRouter {
    static let shared = URLRouter()
    private init() {}

    @MainActor
    func route(_ url: URL) {
        let settings = AppSettings.shared
        let profileID = matchedProfileID(for: url, rules: settings.rules)
            ?? settings.defaultProfileID

        guard !profileID.isEmpty,
              let profile = settings.availableProfiles.first(where: { $0.id == profileID }) else {
            logger.warning("No profile found for profileID '\(profileID)' — skipping \(url.absoluteString)")
            return
        }

        ChromeLauncher.open(url, in: profile)
    }

    private func matchedProfileID(for url: URL, rules: [URLRule]) -> String? {
        for rule in rules where rule.isEnabled {
            let subject: String
            if rule.pattern.contains("/") {
                subject = url.absoluteString
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
