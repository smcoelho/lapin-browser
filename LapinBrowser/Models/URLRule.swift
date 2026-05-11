import Foundation

struct URLRule: Identifiable, Codable, Equatable {
    let id: UUID
    var pattern: String      // glob pattern, e.g. "*.apple.com" or "blip.pt/*"
    var profileID: String    // matches BrowserProfile.id
    var label: String        // user-visible label, may be empty
    var isEnabled: Bool
    // Profile identity used by resolveProfileIDs() to re-match profiles after browser updates
    var profileEmail: String?
    var profileDisplayName: String?
    var profileGaiaName: String?
    var browserID: String?   // bundle ID of browser to open URLs in (e.g. "com.google.Chrome")

    init(pattern: String = "", profileID: String = "", label: String = "", isEnabled: Bool = true, browserID: String? = nil) {
        self.id = UUID()
        self.pattern = pattern
        self.profileID = profileID
        self.label = label
        self.isEnabled = isEnabled
        self.browserID = browserID
    }

    func enriched(with profile: BrowserProfile) -> URLRule {
        var copy = self
        copy.profileEmail       = profile.email.isEmpty       ? nil : profile.email
        copy.profileDisplayName = profile.displayName.isEmpty ? nil : profile.displayName
        copy.profileGaiaName    = profile.gaiaName.isEmpty    ? nil : profile.gaiaName
        return copy
    }
}
