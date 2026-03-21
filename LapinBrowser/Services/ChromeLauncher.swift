import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "ChromeLauncher")

struct ChromeLauncher {
    private static let fallbackChromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")

    private static var chromeAppURL: URL {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome")
            ?? fallbackChromeURL
    }

    static func open(_ url: URL, in profile: ChromeProfile) {
        let chromeRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.google.Chrome"
        ).isEmpty

        // NSWorkspace is preferred when Chrome is not running (cold launch with args).
        // Process is used when Chrome is already running (passes args to the binary directly).
        if chromeRunning {
            openWithProcess(url, profile: profile)
        } else {
            openWithWorkspace(url, profile: profile)
        }
    }

    private static func openWithWorkspace(_ url: URL, profile: ChromeProfile) {
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = ["--profile-directory=\(profile.directoryName)"]
        NSWorkspace.shared.open([url], withApplicationAt: chromeAppURL, configuration: config) { _, error in
            if let error = error {
                logger.error("NSWorkspace failed to open Chrome: \(error)")
                // Completion handler runs on a background queue; openWithProcess is safe to call here.
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
