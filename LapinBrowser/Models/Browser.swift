import Foundation

struct Browser: Identifiable, Codable, Hashable {
    let id: String               // bundle ID, used as stable identifier in settings
    let name: String
    let localStatePath: String   // relative to home directory
    let fallbackAppPath: String
    let binaryName: String       // executable name inside Contents/MacOS/
    let supportsProfiles: Bool
}

extension Browser {
    static let googleChrome = Browser(
        id: "com.google.Chrome",
        name: "Google Chrome",
        localStatePath: "Library/Application Support/Google/Chrome/Local State",
        fallbackAppPath: "/Applications/Google Chrome.app",
        binaryName: "Google Chrome",
        supportsProfiles: true
    )
    static let brave = Browser(
        id: "com.brave.Browser",
        name: "Brave",
        localStatePath: "Library/Application Support/BraveSoftware/Brave-Browser/Local State",
        fallbackAppPath: "/Applications/Brave Browser.app",
        binaryName: "Brave Browser",
        supportsProfiles: true
    )
    static let safari = Browser(
        id: "com.apple.Safari",
        name: "Safari",
        localStatePath: "",
        fallbackAppPath: "/Applications/Safari.app",
        binaryName: "Safari",
        supportsProfiles: false
    )
    static let all: [Browser] = [.googleChrome, .brave, .safari]
}
