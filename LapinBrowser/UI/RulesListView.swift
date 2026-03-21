import SwiftUI

struct RulesListView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selection: URLRule.ID? = nil

    var body: some View {
        VStack(spacing: 0) {
            Table(settings.rules, selection: $selection) {
                TableColumn("Enabled") { rule in
                    Toggle("", isOn: Binding(
                        get: { rule.isEnabled },
                        set: { newValue in
                            if let i = settings.rules.firstIndex(where: { $0.id == rule.id }) {
                                settings.rules[i].isEnabled = newValue
                                settings.save()
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .width(55)

                TableColumn("Pattern") { rule in
                    Text(rule.pattern)
                }

                TableColumn("Profile") { rule in
                    let profileName = settings.availableProfiles
                        .first(where: { $0.id == rule.profileID })?.displayName ?? rule.profileID
                    Text(profileName)
                }

                TableColumn("Label") { rule in
                    Text(rule.label)
                }
            }

            Divider()

            HStack(spacing: 0) {
                Button(action: addRule) {
                    Image(systemName: "plus")
                        .frame(width: 26, height: 22)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 22)

                Button(action: removeSelected) {
                    Image(systemName: "minus")
                        .frame(width: 26, height: 22)
                }
                .buttonStyle(.borderless)
                .disabled(selection == nil)

                Spacer()

                Text("\(settings.rules.count) rule\(settings.rules.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            }
            .padding(.horizontal, 4)
        }
    }

    private func addRule() {
        let newRule = URLRule(
            pattern: "",
            profileID: settings.defaultProfileID,
            label: ""
        )
        settings.rules.append(newRule)
        selection = newRule.id
        settings.save()
    }

    private func removeSelected() {
        guard let selectedID = selection else { return }
        settings.rules.removeAll { $0.id == selectedID }
        selection = nil
        settings.save()
    }
}
