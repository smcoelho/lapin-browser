import Foundation

struct BrowserProfile: Identifiable, Codable, Hashable {
    let id: String             // e.g. "Profile 1", "Default"
    let directoryName: String  // profile folder name; passed as --profile-directory argument
    let displayName: String    // user-visible name
    let email: String          // account email, may be empty
    let gaiaName: String       // account display name, may be empty
}
