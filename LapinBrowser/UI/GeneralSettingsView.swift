import OSLog
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Default Profile", selection: $settings.defaultProfileID) {
                    Text("None").tag("")
                    ForEach(settings.availableProfiles) { profile in
                        Text(profile.displayName).tag(profile.id)
                    }
                }
                .onChange(of: settings.defaultProfileID) { _ in
                    settings.save()
                }
            }

            Section {
                Button("Set as Default Browser") {
                    setAsDefaultBrowser()
                }
            }

            if settings.availableProfiles.isEmpty {
                Section {
                    Text("No Chrome profiles found. Make sure Google Chrome is installed.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func setAsDefaultBrowser() {
        let logger = Logger(subsystem: "pt.lapin.browser", category: "GeneralSettings")
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL,
            toOpenURLsWithScheme: "http"
        ) { error in
            if let error { logger.error("Failed to set default browser (http): \(error)") }
        }
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL,
            toOpenURLsWithScheme: "https"
        ) { error in
            if let error { logger.error("Failed to set default browser (https): \(error)") }
        }
    }
}
