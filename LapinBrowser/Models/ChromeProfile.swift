import Foundation

struct ChromeProfile: Identifiable, Codable, Hashable {
    let id: String          // e.g. "Profile 1", "Default"
    let directoryName: String  // the Chrome profile folder name (e.g. "Profile 1", "Default"); passed as --profile-directory argument
    let displayName: String    // user-visible name
    let email: String          // gaia email, may be empty
    let gaiaName: String       // Google account name, may be empty
}
