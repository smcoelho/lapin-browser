import Foundation

struct URLRule: Identifiable, Codable, Equatable {
    let id: UUID
    var pattern: String      // glob pattern, e.g. "*.apple.com" or "blip.pt/*"
    var profileID: String    // matches ChromeProfile.id
    var label: String        // user-visible label, may be empty
    var isEnabled: Bool
    // Profile identity for cross-machine iCloud sync resolution (populated at save time)
    var profileEmail: String?
    var profileDisplayName: String?
    var profileGaiaName: String?

    init(pattern: String = "", profileID: String = "", label: String = "", isEnabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.profileID = profileID
        self.label = label
        self.isEnabled = isEnabled
    }

    func enriched(with profile: BrowserProfile) -> URLRule {
        var copy = self
        copy.profileEmail       = profile.email.isEmpty       ? nil : profile.email
        copy.profileDisplayName = profile.displayName.isEmpty ? nil : profile.displayName
        copy.profileGaiaName    = profile.gaiaName.isEmpty    ? nil : profile.gaiaName
        return copy
    }
}
