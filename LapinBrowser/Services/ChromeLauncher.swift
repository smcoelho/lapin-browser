import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "ChromeLauncher")

struct ChromeLauncher {
    static let chromeAppURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")

    static func open(_ url: URL, in profile: ChromeProfile) {
        let chromeRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.google.Chrome"
        ).isEmpty

        if chromeRunning {
            openWithProcess(url, profile: profile)
        } else {
            openWithWorkspace(url, profile: profile)
        }
    }

    private static func openWithWorkspace(_ url: URL, profile: ChromeProfile) {
        let config = NSWorkspaceOpenConfiguration()
        config.arguments = ["--profile-directory=\(profile.directoryName)"]
        NSWorkspace.shared.open([url], withApplicationAt: chromeAppURL, configuration: config) { _, error in
            if let error = error {
                logger.error("NSWorkspace failed to open Chrome: \(error)")
                // Fallback to Process if NSWorkspace fails
                openWithProcess(url, profile: profile)
            }
        }
    }

    private static func openWithProcess(_ url: URL, profile: ChromeProfile) {
        let process = Process()
        process.executableURL = chromeAppURL.appendingPathComponent("Contents/MacOS/Google Chrome")
        process.arguments = ["--profile-directory=\(profile.directoryName)", url.absoluteString]
        do {
            try process.run()
        } catch {
            logger.error("Process failed to open Chrome: \(error)")
        }
    }
}
