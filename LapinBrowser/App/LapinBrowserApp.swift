import SwiftUI

@main
struct LapinBrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra("Lapin Browser", systemImage: "hare") {
            MenuBarView()
                .environmentObject(settings)
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}
