import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if #available(macOS 14.0, *) {
                OpenSettingsButton()
            } else {
                Button("Open Settings") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
            Divider()
            Button("Quit Lapin Browser") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(4)
    }
}

/// `SettingsLink` doesn't activate the app, and as an `LSUIElement` app Lapin
/// isn't active when the menu is used, so the window would open behind others.
@available(macOS 14.0, *)
private struct OpenSettingsButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Open Settings") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
    }
}
