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
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL,
            toOpenURLsWithScheme: "http"
        ) { _ in }
        NSWorkspace.shared.setDefaultApplication(
            at: Bundle.main.bundleURL,
            toOpenURLsWithScheme: "https"
        ) { _ in }
    }
}
