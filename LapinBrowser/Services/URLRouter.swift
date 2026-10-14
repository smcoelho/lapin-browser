import Foundation
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "URLRouter")

struct URLRouter {
    static let shared = URLRouter()
    private init() {}

    @MainActor
    func route(_ url: URL) {
        let settings = AppSettings.shared
        let target = URLRouter.resolveTarget(
            for: url,
            rules: settings.rules,
            defaultProfileID: settings.defaultProfileID,
            activeBrowserID: settings.activeBrowserID,
            profiles: settings.availableProfiles
        )
        BrowserLauncher.open(url, in: target.profile, browser: target.browser)
    }

    struct RouteTarget {
        let browser: Browser
        /// nil when no profile could be resolved — the URL still opens, in the browser's
        /// own last-used profile, rather than being dropped.
        let profile: BrowserProfile?
    }

    static func resolveTarget(
        for url: URL,
        rules: [URLRule],
        defaultProfileID: String,
        activeBrowserID: String,
        profiles: [BrowserProfile]
    ) -> RouteTarget {
        let matched = matchedRule(for: url, rules: rules)
        // A rule saved with no profile ("None") defers to the default profile.
        let ruleProfileID = matched?.profileID ?? ""
        let profileID = ruleProfileID.isEmpty ? defaultProfileID : ruleProfileID

        // Resolve browser: rule's browserID > global active browser
        let browserID = matched?.browserID ?? activeBrowserID
        let browser = Browser.all.first { $0.id == browserID }
            ?? Browser.all.first { $0.id == activeBrowserID }
            ?? .googleChrome

        // Resolve profile — scope to the pinned browser if the rule has one
        let profile: BrowserProfile?
        if let bid = matched?.browserID {
            if let exact = profiles.first(where: { $0.id == profileID && $0.browserID == bid }) {
                profile = exact
            } else {
                profile = profiles.first { $0.browserID == bid }
                if profile != nil {
                    logger.warning("Profile '\(profileID)' not found for browser '\(bid)' — falling back to first available profile")
                }
            }
        } else {
            profile = profileID.isEmpty ? nil : profiles.first { $0.id == profileID }
        }

        if profile == nil {
            logger.warning("No profile resolved for '\(browser.id)' — opening \(url.absoluteString) without one")
        }
        return RouteTarget(browser: browser, profile: profile)
    }

    // Internal so URLRouterTests can exercise matching logic directly.
    // Patterns with no `/` are matched against the URL host only.
    // Patterns with `/` are matched against the full absoluteString (including scheme).
    // Leading `www.` and `ftp.` prefixes in the URL are ignored when no direct match is found,
    // so a pattern like `apple.com` also matches `https://www.apple.com`.
    static func matchedProfileID(for url: URL, rules: [URLRule]) -> String? {
        matchedRule(for: url, rules: rules)?.profileID
    }

    // Returns the first matching enabled rule, or nil.
    static func matchedRule(for url: URL, rules: [URLRule]) -> URLRule? {
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
                return rule
            }
            if let stripped = strippedSubject(subject, isFullURL: isFullURL),
               fnmatch(rule.pattern, stripped, FNM_CASEFOLD) == 0 {
                return rule
            }
            // Also try with http normalized to https, so https:// rules catch http:// URLs.
            if let httpsSubject = httpToHttpsSubject(subject, isFullURL: isFullURL) {
                if fnmatch(rule.pattern, httpsSubject, FNM_CASEFOLD) == 0 {
                    return rule
                }
                if let stripped = strippedSubject(httpsSubject, isFullURL: isFullURL),
                   fnmatch(rule.pattern, stripped, FNM_CASEFOLD) == 0 {
                    return rule
                }
            }
        }
        return nil
    }

    /// Returns a copy of `subject` with the scheme changed from `http` to `https`,
    /// or `nil` when the subject does not start with `http://`.
    private static func httpToHttpsSubject(_ subject: String, isFullURL: Bool) -> String? {
        guard isFullURL, subject.lowercased().hasPrefix("http://") else { return nil }
        return "https://" + subject.dropFirst("http://".count)
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
