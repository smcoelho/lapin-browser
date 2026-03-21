import SwiftUI

struct MenuBarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("Open Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit Lapin Browser") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(4)
    }
}
