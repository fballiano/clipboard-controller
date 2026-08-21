import AppKit
import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem { Label("General", systemImage: "gearshape") }

            CleaningSettingsView(model: model)
                .tabItem { Label("Cleaning", systemImage: "wand.and.sparkles") }

            PrivacySettingsView(model: model)
                .tabItem { Label("Privacy", systemImage: "hand.raised") }

            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
        }
        .frame(width: 520, height: 420)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    let model: AppModel

    var body: some View {
        @Bindable var preferences = model.preferences
        @Bindable var loginItem = model.loginItem

        Form {
            Section("History") {
                Toggle("Record the clipboard", isOn: $preferences.recordClipboard)
                Toggle("Store the images", isOn: $preferences.storeImages)

                Stepper(value: $preferences.menuClipCount, in: 1 ... 50) {
                    Text("Show \(preferences.menuClipCount) clips in the menu")
                }
            }

            Section {
                Toggle("Delete the old clips automatically", isOn: $preferences.limitsStoredClips)

                if preferences.limitsStoredClips {
                    Stepper(value: $preferences.maxStoredClips, in: 10 ... 9999, step: 10) {
                        Text("Keep the last \(preferences.maxStoredClips) clips")
                    }
                }

                Toggle("Delete a clip after some days", isOn: $preferences.limitsClipAge)

                if preferences.limitsClipAge {
                    Stepper(value: $preferences.maxClipAgeDays, in: 1 ... 365) {
                        Text("Delete a clip after \(preferences.maxClipAgeDays) days")
                    }
                }
            } header: {
                Text("Limits")
            } footer: {
                Text("A pinned clip stays. A limit never deletes it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Start clipboard-controller at login", isOn: $loginItem.isEnabled)

                if let error = loginItem.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: preferences.maxStoredClips) { model.applyLimits() }
        .onChange(of: preferences.maxClipAgeDays) { model.applyLimits() }
    }
}

// MARK: - Cleaning

private struct CleaningSettingsView: View {
    let model: AppModel

    var body: some View {
        @Bindable var preferences = model.preferences

        Form {
            Section {
                Toggle("Clean each new clipboard", isOn: $preferences.automaticCleaning)
            } footer: {
                Text("""
                The app never touches a file, a picture without text, or the \
                clipboard of a password field.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section("Formatting") {
                Toggle("Remove the formatting", isOn: $preferences.removeFormatting)
                Toggle("Keep the links", isOn: $preferences.preserveLinks)
                    .disabled(!preferences.removeFormatting)
            }

            Section("Text") {
                Toggle("Remove the invisible characters", isOn: $preferences.removeInvisibleCharacters)
                Toggle("Normalize the quotes", isOn: $preferences.normalizeQuotes)
                Toggle("Normalize the ends of the lines", isOn: $preferences.normalizeNewlines)
                Toggle("Turn a bullet into a hyphen", isOn: $preferences.normalizeLists)
                Toggle("Remove the space at the start and at the end", isOn: $preferences.trimWhitespace)
            }

            Section {
                Toggle("Remove the tracking parameters of a URL", isOn: $preferences.removeTrackingParameters)
            } footer: {
                Text("""
                The app removes about 200 known parameters, for example \
                utm_source and fbclid, and the parameters that X, TikTok, \
                Facebook, YouTube and Amazon add.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Privacy

private struct PrivacySettingsView: View {
    let model: AppModel

    var body: some View {
        @Bindable var preferences = model.preferences

        Form {
            Section {
                Toggle("Private mode", isOn: $preferences.privateMode)
            } footer: {
                Text("""
                The app stores nothing while the private mode is on. The menu \
                bar icon carries a line, so the state is always visible.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Section("Do not record from these applications") {
                AppListEditor(
                    bundleIDs: $preferences.excludedRecordingApps,
                    addTitle: "Add an application…"
                )
            }

            Section {
                AppListEditor(
                    bundleIDs: $preferences.excludedCleaningApps,
                    addTitle: "Add an application…"
                )
            } header: {
                Text("Do not clean the clipboard of these applications")
            } footer: {
                Text("""
                A password manager marks its clipboard, and the app skips it \
                without a rule. These lists are for the rest.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

/// A list of applications, with a button that opens the Applications folder.
private struct AppListEditor: View {
    @Binding var bundleIDs: [String]
    let addTitle: String

    @State private var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if bundleIDs.isEmpty {
                Text("No application")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                List(selection: $selection) {
                    ForEach(bundleIDs, id: \.self) { bundleID in
                        Text(AppListEditor.name(of: bundleID))
                            .tag(bundleID)
                    }
                }
                .frame(height: 90)
            }

            HStack {
                Button(addTitle) { add() }

                Button("Remove") { remove() }
                    .disabled(selection == nil)
            }
        }
    }

    private func add() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.title = "Select the applications"

        NSApp.activate()

        guard panel.runModal() == .OK else { return }

        for url in panel.urls {
            guard let bundleID = Bundle(url: url)?.bundleIdentifier else { continue }
            guard !bundleIDs.contains(bundleID) else { continue }
            bundleIDs.append(bundleID)
        }
    }

    private func remove() {
        guard let selection else { return }

        bundleIDs.removeAll { $0 == selection }
        self.selection = nil
    }

    /// The name of the application, or the bundle identifier when the
    /// application is no longer installed.
    static func name(of bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID
        }

        return FileManager.default.displayName(atPath: url.path)
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Automatic cleaning:", name: .toggleAutomaticCleaning)
                KeyboardShortcuts.Recorder("Clean the clipboard now:", name: .cleanNow)
                KeyboardShortcuts.Recorder("Private mode:", name: .togglePrivateMode)
                KeyboardShortcuts.Recorder("Open the history:", name: .showHistory)
            } footer: {
                Text("These shortcuts work in every application.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
