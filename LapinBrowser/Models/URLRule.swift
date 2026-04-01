import Foundation

struct URLRule: Identifiable, Codable {
    let id: UUID
    var pattern: String      // glob pattern, e.g. "*.apple.com" or "blip.pt/*"
    var profileID: String    // matches ChromeProfile.id
    var label: String        // user-visible label, may be empty
    var isEnabled: Bool

    init(pattern: String = "", profileID: String = "", label: String = "", isEnabled: Bool = true) {
        self.id = UUID()
        self.pattern = pattern
        self.profileID = profileID
        self.label = label
        self.isEnabled = isEnabled
    }
}
