import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Detect Chrome profiles and populate available profiles
        let profiles = ChromeProfileDetector.detect()
        Task { @MainActor in
            AppSettings.shared.availableProfiles = profiles
            // Set a default profile if none configured yet
            if AppSettings.shared.defaultProfileID.isEmpty, let first = profiles.first {
                AppSettings.shared.defaultProfileID = first.id
            }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            Task { @MainActor in
                URLRouter.shared.route(url)
            }
        }
    }
}
