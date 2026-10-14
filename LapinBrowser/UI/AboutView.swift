import AppKit
import SwiftUI

struct AboutView: View {
    private let info = Bundle.main.infoDictionary ?? [:]

    private var version: String {
        let short = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Lapin Browser")
                .font(.title)
                .bold()

            Text(version)
                .foregroundStyle(.secondary)

            Text("Routes every link to the right browser and profile.")
                .multilineTextAlignment(.center)

            Link("github.com/smcoelho/lapin-browser",
                 destination: URL(string: "https://github.com/smcoelho/lapin-browser")!)

            if let copyright = info["NSHumanReadableCopyright"] as? String {
                Text(copyright)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
