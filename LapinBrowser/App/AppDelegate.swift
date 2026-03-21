import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let profiles = ChromeProfileDetector.detect()
        AppSettings.shared.availableProfiles = profiles
        if AppSettings.shared.defaultProfileID.isEmpty, let first = profiles.first {
            AppSettings.shared.defaultProfileID = first.id
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: nil
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    @objc private func windowDidResignKey(_ notification: Notification) {
        // SwiftUI Settings windows are hidden (orderOut:), not closed — so
        // willCloseNotification never fires. Check visibility after the
        // current run-loop tick to let the window finish hiding.
        DispatchQueue.main.async {
            let hasVisible = NSApp.windows.contains { $0.isVisible && $0.canBecomeKey }
            if !hasVisible {
                NSApp.setActivationPolicy(.accessory)
            }
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
