import Foundation

struct ChromeProfile: Identifiable, Codable, Hashable {
    let id: String          // e.g. "Profile 1", "Default"
    let directoryName: String  // same as id, used for --profile-directory arg
    let displayName: String    // user-visible name
    let email: String          // gaia email, may be empty
    let gaiaName: String       // Google account name, may be empty
}
