import AppKit
import SwiftUI

/// Embedded inside a TableColumn cell — traverses up via superview to reach NSTableView
/// and installs a doubleAction. Must be placed inside a table cell to work.
private struct TableDoubleClickHook: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> HookView {
        HookView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: HookView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func handleDoubleClick() { action() }
    }

    class HookView: NSView {
        weak var coordinator: Coordinator?

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            // Walk up from the cell view — guaranteed to find NSTableView.
            var v: NSView? = self
            while let current = v {
                if let table = current as? NSTableView {
                    table.doubleAction = #selector(Coordinator.handleDoubleClick)
                    table.target = coordinator
                    return
                }
                v = current.superview
            }
        }
    }
}

struct RulesListView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selection: URLRule.ID? = nil
    @State private var editingRule: URLRule? = nil

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
                        .background(TableDoubleClickHook(action: editSelected))
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

                Divider().frame(height: 22)

                Button(action: editSelected) {
                    Image(systemName: "pencil")
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
        .sheet(item: $editingRule) { rule in
            RuleEditView(rule: rule, profiles: settings.availableProfiles) { updated in
                if let i = settings.rules.firstIndex(where: { $0.id == updated.id }) {
                    settings.rules[i] = updated
                } else {
                    settings.rules.append(updated)
                    selection = updated.id
                }
                settings.save()
            }
        }
    }

    private func addRule() {
        // Open the edit sheet with a fresh rule; only append+save if the user clicks Save.
        let newRule = URLRule(
            pattern: "",
            profileID: settings.defaultProfileID,
            label: ""
        )
        editingRule = newRule
    }

    private func removeSelected() {
        guard let selectedID = selection else { return }
        settings.rules.removeAll { $0.id == selectedID }
        selection = nil
        settings.save()
    }

    private func editSelected() {
        editingRule = settings.rules.first(where: { $0.id == selection })
    }
}

struct RuleEditView: View {
    @State var rule: URLRule
    let profiles: [BrowserProfile]
    let onSave: (URLRule) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Rule").font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pattern").font(.callout).foregroundStyle(.secondary)
                TextField("", text: $rule.pattern)
                    .textFieldStyle(.roundedBorder)
                Text("Use *.apple.com to match by host, or https://example.com/* to match the full URL.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Label").font(.callout).foregroundStyle(.secondary)
                TextField("Optional note", text: $rule.label)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Profile").font(.callout).foregroundStyle(.secondary)
                Picker("", selection: $rule.profileID) {
                    Text("None").tag("")
                    ForEach(profiles) { profile in
                        Text(profile.displayName).tag(profile.id)
                    }
                }
                .labelsHidden()
            }

            Toggle("Enabled", isOn: $rule.isEnabled)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(rule.pattern.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
