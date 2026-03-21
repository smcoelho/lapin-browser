import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        let profiles = ChromeProfileDetector.detect()
        AppSettings.shared.availableProfiles = profiles
        if AppSettings.shared.defaultProfileID.isEmpty, let first = profiles.first {
            AppSettings.shared.defaultProfileID = first.id
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            for url in urls {
                URLRouter.shared.route(url)
            }
        }
    }
}
