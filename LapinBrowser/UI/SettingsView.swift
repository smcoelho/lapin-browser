import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            RulesListView()
                .environmentObject(settings)
                .tabItem { Label("Rules", systemImage: "list.bullet") }

            GeneralSettingsView()
                .environmentObject(settings)
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 560, height: 400)
    }
}
