import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "pt.lapin.browser", category: "BrowserLauncher")

struct BrowserLauncher {
    private static func appURL(for browser: Browser) -> URL {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.id)
            ?? URL(fileURLWithPath: browser.fallbackAppPath)
    }

    static func open(_ url: URL, in profile: BrowserProfile, browser: Browser) {
        let browserRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: browser.id
        ).isEmpty

        // NSWorkspace is preferred when the browser is not running (cold launch with args).
        // Process is used when the browser is already running (passes args to the binary directly).
        if browserRunning {
            openWithProcess(url, profile: profile, browser: browser)
        } else {
            openWithWorkspace(url, profile: profile, browser: browser)
        }
    }

    private static func openWithWorkspace(_ url: URL, profile: BrowserProfile, browser: Browser) {
        let browserURL = appURL(for: browser)
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = ["--profile-directory=\(profile.directoryName)"]
        NSWorkspace.shared.open([url], withApplicationAt: browserURL, configuration: config) { _, error in
            if let error = error {
                logger.error("NSWorkspace failed to open \(browser.name): \(error)")
                // Completion handler runs on a background queue; openWithProcess is safe to call here.
                openWithProcess(url, profile: profile, browser: browser)
            }
        }
    }

    private static func openWithProcess(_ url: URL, profile: BrowserProfile, browser: Browser) {
        let browserURL = appURL(for: browser)
        let process = Process()
        process.executableURL = browserURL.appendingPathComponent("Contents/MacOS/\(browser.binaryName)")
        process.arguments = ["--profile-directory=\(profile.directoryName)", url.absoluteString]
        do {
            try process.run()
        } catch {
            logger.error("Process failed to open \(browser.name): \(error)")
        }
    }
}
