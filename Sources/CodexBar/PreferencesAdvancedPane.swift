import AppKit
import SwiftUI

@MainActor
struct AdvancedPane: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var store: UsageStore
    @State private var isInstallingCLI = false
    @State private var cliStatus: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 6) {
                    Text("Refresh cadence")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Picker("", selection: self.$settings.refreshFrequency) {
                        ForEach(RefreshFrequency.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if self.settings.refreshFrequency == .manual {
                        Text("Auto-refresh is off; use the menu's Refresh command.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("Display")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: "Show usage as used",
                        subtitle: "Progress bars fill as you consume quota (instead of showing remaining).",
                        binding: self.$settings.usageBarsShowUsed)
                    PreferenceToggleRow(
                        title: "Merge Icons",
                        subtitle: "Use a single menu bar icon with a provider switcher.",
                        binding: self.$settings.mergeIcons)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: "Check provider status",
                        subtitle: "Polls OpenAI/Claude status pages and surfaces incidents in the icon and menu.",
                        binding: self.$settings.statusChecksEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("Fun")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: "Surprise me",
                        subtitle: "Check if you like your agents having some fun up there.",
                        binding: self.$settings.randomBlinkEnabled)
                }

                Divider()

                SettingsSection(contentSpacing: 10) {
                    HStack(spacing: 12) {
                        Button {
                            Task { await self.installCLI() }
                        } label: {
                            if self.isInstallingCLI {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Install CLI")
                            }
                        }
                        .disabled(self.isInstallingCLI)

                        if let status = self.cliStatus {
                            Text(status)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Text("Symlink CodexBarCLI to /usr/local/bin and /opt/homebrew/bin as codexbar.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Divider()

                SettingsSection(contentSpacing: 10) {
                    PreferenceToggleRow(
                        title: "Show Debug Settings",
                        subtitle: "Expose troubleshooting tools in the Debug tab.",
                        binding: self.$settings.debugMenuEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - CLI installer

    private func installCLI() async {
        guard !self.isInstallingCLI else { return }
        self.isInstallingCLI = true
        defer { self.isInstallingCLI = false }

        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("CodexBarCLI")

        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            await MainActor.run { self.cliStatus = "Helper missing; reinstall CodexBar." }
            return
        }

        let installScript = """
        #!/usr/bin/env bash
        set -euo pipefail
        HELPER="\(helperURL.path)"
        TARGETS=("/usr/local/bin/codexbar" "/opt/homebrew/bin/codexbar")

        for t in "${TARGETS[@]}"; do
          mkdir -p "$(dirname "$t")"
          ln -sf "$HELPER" "$t"
          echo "Linked $t -> $HELPER"
        done
        """

        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("install_codexbar_cli.sh")

        do {
            defer { try? FileManager.default.removeItem(at: scriptURL) }
            try installScript.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

            let escapedPath = scriptURL.path.replacingOccurrences(of: "\"", with: "\\\"")
            let appleScript = "do shell script \"bash \\\"\(escapedPath)\\\"\" with administrator privileges"

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript]
            let stderrPipe = Pipe()
            process.standardError = stderrPipe

            try process.run()
            process.waitUntilExit()
            let status: String
            if process.terminationStatus == 0 {
                status = "Installed. Try: codexbar usage"
            } else {
                let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let msg = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                status = "Failed: \(msg ?? "error")"
            }
            await MainActor.run {
                self.cliStatus = status
            }
        } catch {
            await MainActor.run { self.cliStatus = "Failed: \(error.localizedDescription)" }
        }
    }
}
