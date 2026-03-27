import CoreServices
import OSLog
import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Browser", selection: $settings.activeBrowserID) {
                    ForEach(settings.availableBrowsers) { browser in
                        Text(browser.name).tag(browser.id)
                    }
                }
                .onChange(of: settings.activeBrowserID) { _ in
                    settings.save()
                    refreshProfiles()
                }

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
                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { applyLaunchAtLogin($0) }
                ))
            }

            Section {
                Button("Set as Default Browser") {
                    setAsDefaultBrowser()
                }
                Button("Edit settings.json") {
                    NSWorkspace.shared.open(AppSettings.shared.settingsURL)
                }
            }

            if settings.availableProfiles.isEmpty {
                Section {
                    Text("No profiles found. Make sure your selected browser is installed.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func applyLaunchAtLogin(_ enable: Bool) {
        if enable {
            LoginItemService.enable { success, error in
                if success {
                    settings.launchAtLogin = true
                    settings.save()
                } else {
                    settings.launchAtLogin = false
                    if let nsError = error as? NSError,
                       nsError.code == kSMErrorLaunchDeniedByUser {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                }
            }
        } else {
            LoginItemService.disable { success, _ in
                settings.launchAtLogin = success ? false : settings.launchAtLogin
                settings.save()
            }
        }
    }

    private func refreshProfiles() {
        guard let browser = Browser.all.first(where: { $0.id == settings.activeBrowserID }) else { return }
        let profiles = BrowserProfileDetector.detect(for: browser)
        settings.availableProfiles = profiles
        if !profiles.contains(where: { $0.id == settings.defaultProfileID }) {
            settings.defaultProfileID = profiles.first?.id ?? ""
            settings.save()
        }
    }

    private func setAsDefaultBrowser() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let id = bundleID as CFString
        // LSSetDefaultHandlerForURLScheme uses the bundle identifier rather than
        // the file path, so it works regardless of where the app is installed.
        LSSetDefaultHandlerForURLScheme("http" as CFString, id)
        LSSetDefaultHandlerForURLScheme("https" as CFString, id)
    }
}
