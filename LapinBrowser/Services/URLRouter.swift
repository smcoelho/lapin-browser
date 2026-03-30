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

        let activeBrowser = Browser.all.first { $0.id == settings.activeBrowserID } ?? .googleChrome
        BrowserLauncher.open(url, in: profile, browser: activeBrowser)
    }

    // Internal so URLRouterTests can exercise matching logic directly.
    // Patterns with no `/` are matched against the URL host only.
    // Patterns with `/` are matched against the full absoluteString (including scheme).
    // Leading `www.` and `ftp.` prefixes in the URL are ignored when no direct match is found,
    // so a pattern like `apple.com` also matches `https://www.apple.com`.
    static func matchedProfileID(for url: URL, rules: [URLRule]) -> String? {
        for rule in rules where rule.isEnabled {
            let isFullURL = rule.pattern.contains("/")
            let subject: String
            if isFullURL {
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
            if let stripped = strippedSubject(subject, isFullURL: isFullURL),
               fnmatch(rule.pattern, stripped, FNM_CASEFOLD) == 0 {
                return rule.profileID
            }
        }
        return nil
    }

    /// Strips a leading `www.` or `ftp.` from the host portion of `subject`,
    /// returning the modified string, or `nil` when neither prefix is present.
    ///
    /// For full-URL subjects the host sits between `://` and the first `/`.
    /// For host-only subjects the entire string is the host.
    private static func strippedSubject(_ subject: String, isFullURL: Bool) -> String? {
        let prefixes = ["www.", "ftp."]
        if isFullURL {
            guard let schemeEnd = subject.range(of: "://") else { return nil }
            let afterScheme = subject[schemeEnd.upperBound...]
            let hostEnd = afterScheme.firstIndex(of: "/") ?? afterScheme.endIndex
            let host = String(afterScheme[afterScheme.startIndex ..< hostEnd])
            for prefix in prefixes {
                if host.lowercased().hasPrefix(prefix) {
                    let hostStart = schemeEnd.upperBound
                    let hostEndIdx = subject.index(hostStart, offsetBy: host.count)
                    return subject.replacingCharacters(
                        in: hostStart ..< hostEndIdx,
                        with: String(host.dropFirst(prefix.count))
                    )
                }
            }
            return nil
        } else {
            for prefix in prefixes {
                if subject.lowercased().hasPrefix(prefix) {
                    return String(subject.dropFirst(prefix.count))
                }
            }
            return nil
        }
    }
}
