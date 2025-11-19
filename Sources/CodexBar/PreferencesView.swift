import SwiftUI
import AppKit

enum PreferencesTab: String, Hashable {
    case general
    case about
    case debug

    static let windowWidth: CGFloat = 374
    static let windowHeight: CGFloat = 374

    var preferredHeight: CGFloat {
        PreferencesTab.windowHeight
    }
}

@MainActor
struct PreferencesView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var store: UsageStore
    let updater: UpdaterProviding
    @ObservedObject var selection: PreferencesSelection
    @State private var contentHeight: CGFloat = PreferencesTab.general.preferredHeight

    var body: some View {
        TabView(selection: self.$selection.tab) {
            GeneralPane(settings: self.settings, store: self.store)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(PreferencesTab.general)

            AboutPane(updater: self.updater)
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(PreferencesTab.about)

            if self.settings.debugMenuEnabled {
                DebugPane(settings: self.settings, store: self.store)
                    .tabItem { Label("Debug", systemImage: "ladybug") }
                    .tag(PreferencesTab.debug)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(width: PreferencesTab.windowWidth, height: self.contentHeight)
        .onAppear {
            self.updateHeight(for: self.selection.tab, animate: false)
            self.ensureValidTabSelection()
        }
        .onChange(of: self.selection.tab) { _, newValue in
            self.updateHeight(for: newValue, animate: true)
        }
        .onChange(of: self.settings.debugMenuEnabled) { _, _ in
            self.ensureValidTabSelection()
        }
    }

    private func updateHeight(for tab: PreferencesTab, animate: Bool) {
        let change = {
            self.contentHeight = tab.preferredHeight
        }
        if animate {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                change()
            }
        } else {
            change()
        }
    }

    private func ensureValidTabSelection() {
        if !self.settings.debugMenuEnabled && self.selection.tab == .debug {
            self.selection.tab = .general
            self.updateHeight(for: .general, animate: true)
        }
    }
}

// MARK: - General

@MainActor
private struct GeneralPane: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var store: UsageStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        PreferenceToggleRow(
                            title: "Show Codex usage",
                            subtitle: self.providerSubtitle(.codex),
                            binding: self.codexBinding)

                        self.codexSigningStatus()
                    }
                    .padding(.bottom, 18)

                    PreferenceToggleRow(
                        title: "Show Claude Code usage",
                        subtitle: self.providerSubtitle(.claude),
                        binding: self.claudeBinding)
                }

                Divider()

                SettingsSection(contentSpacing: 6) {
                    Text("Refresh cadence")
                        .font(.footnote.weight(.semibold))
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

                SettingsSection(contentSpacing: 0) {
                    PreferenceToggleRow(
                        title: "Start at Login",
                        subtitle: "Automatically opens CodexBar when you start your Mac.",
                        binding: self.$settings.launchAtLogin)
                    HStack {
                        Spacer()
                        Button("Quit CodexBar") {
                            NSApp.terminate(nil)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.top, 8)
                }

                if self.settings.debugMenuEnabled {
                    SettingsSection(title: "Diagnostics", caption: "Tools that help reproduce tricky states.") {
                        PreferenceToggleRow(
                            title: "Dump credits HTML to /tmp",
                            subtitle: "For diagnostics only.",
                            binding: self.$settings.creditsDebugDump)
                        Button("Replay loading animation") {
                            NotificationCenter.default.post(name: .codexbarDebugReplayAllAnimations, object: nil)
                            self.store.replayLoadingAnimation()
                        }
                        Button("Dump Claude probe output") {
                            Task { await self.store.debugDumpClaude() }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var codexBinding: Binding<Bool> {
        Binding(
            get: { self.settings.showCodexUsage },
            set: { newValue in
                self.settings.showCodexUsage = newValue
            })
    }

    private var claudeBinding: Binding<Bool> {
        Binding(
            get: { self.settings.showClaudeUsage },
            set: { newValue in
                self.settings.showClaudeUsage = newValue
            })
    }

    private func providerSubtitle(_ provider: UsageProvider) -> String {
        let cliName = provider == .codex ? "codex" : "claude"
        let version = provider == .codex ? self.store.codexVersion : self.store.claudeVersion
        let versionText = version ?? "not detected"

        let usageText: String
        if let snapshot = self.store.snapshot(for: provider) {
            let timestamp = snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened)
            usageText = "usage fetched \(timestamp)"
        } else if self.store.isStale(provider: provider) {
            usageText = "last fetch failed"
        } else {
            usageText = "usage not fetched yet"
        }

        return "\(cliName) \(versionText) • \(usageText)"
    }

    @ViewBuilder
    private func codexSigningStatus() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let credits = self.store.credits {
                Text("Signed in to Codex.")
                    .font(.footnote.weight(.semibold))
                Text(self.creditsSummary(credits))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Sign in to OpenAI to see your available credits.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if self.store.credits != nil, let lastError = self.store.lastCreditsError {
                Text(self.truncatedError(lastError))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if self.store.credits == nil {
                Button("Sign in to fetch credits…") { CreditsSignInWindow.present() }
            } else {
                Button("Log out / clear cookies") {
                    Task { await self.store.clearCookies() }
                }
            }
        }
    }

    private func truncatedError(_ error: String) -> String {
        let prefix = "Sign-in issue: "
        let maxLength = 160
        var message = error.trimmingCharacters(in: .whitespacesAndNewlines)
        if message.count > maxLength {
            let idx = message.index(message.startIndex, offsetBy: maxLength)
            message = "\(message[..<idx])…"
        }
        return prefix + message
    }

    private func creditsSummary(_ snapshot: CreditsSnapshot) -> String {
        let amount = snapshot.remaining.formatted(.number.precision(.fractionLength(0...2)))
        let timestamp = snapshot.updatedAt.formatted(date: .abbreviated, time: .shortened)
        return "Remaining \(amount) credits as of \(timestamp)."
    }
}

// MARK: - About

@MainActor
private struct AboutPane: View {
    let updater: UpdaterProviding
    @State private var iconHover = false
    @State private var autoUpdateEnabled = false
    @State private var didLoadUpdaterState = false

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }

    var body: some View {
        VStack(spacing: 12) {
            if let image = NSApplication.shared.applicationIconImage {
                Button(action: self.openProjectHome) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 92, height: 92)
                        .cornerRadius(16)
                        .scaleEffect(self.iconHover ? 1.05 : 1.0)
                        .shadow(color: self.iconHover ? .accentColor.opacity(0.25) : .clear, radius: 6)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        self.iconHover = hovering
                    }
                }
            }

            VStack(spacing: 2) {
                Text("CodexBar")
                    .font(.title3).bold()
                Text("Version \(self.versionString)")
                    .foregroundStyle(.secondary)
                Text("May your tokens never run out—keep Codex limits in view.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .center, spacing: 6) {
                AboutLinkRow(icon: "chevron.left.slash.chevron.right", title: "GitHub", url: "https://github.com/steipete/CodexBar")
                AboutLinkRow(icon: "globe", title: "Website", url: "https://steipete.me")
                AboutLinkRow(icon: "bird", title: "Twitter", url: "https://twitter.com/steipete")
                AboutLinkRow(icon: "envelope", title: "Email", url: "mailto:peter@steipete.me")
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)

            Divider()

            if self.updater.isAvailable {
                VStack(spacing: 10) {
                    Toggle("Check for updates automatically", isOn: self.$autoUpdateEnabled)
                        .toggleStyle(.checkbox)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Button("Check for Updates…") { self.updater.checkForUpdates(nil) }
                }
            } else {
                Text("Updates unavailable in this build.")
                    .foregroundStyle(.secondary)
            }

            Text("© 2025 Peter Steinberger. MIT License.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .onAppear {
            guard !self.didLoadUpdaterState else { return }
            self.autoUpdateEnabled = self.updater.automaticallyChecksForUpdates
            self.didLoadUpdaterState = true
        }
        .onChange(of: self.autoUpdateEnabled) { _, newValue in
            self.updater.automaticallyChecksForUpdates = newValue
        }
    }

    private func openProjectHome() {
        guard let url = URL(string: "https://github.com/steipete/CodexBar") else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Debug

@MainActor
private struct DebugPane: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var store: UsageStore

    var body: some View {
        Form {
            Section("Diagnostics toggles") {
                Toggle("Dump credits HTML to /tmp", isOn: self.$settings.creditsDebugDump)
                Toggle("Show debug menu items", isOn: self.$settings.debugMenuEnabled)
                    .disabled(true)
            }

            Section("Actions") {
                Button("Replay loading animation") {
                    NotificationCenter.default.post(name: .codexbarDebugReplayAllAnimations, object: nil)
                    self.store.replayLoadingAnimation()
                }
                Button("Dump Claude probe output") {
                    Task { await self.store.debugDumpClaude() }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Reusable rows

@MainActor
private struct PreferenceToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var binding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(isOn: self.$binding) {
                Text(self.title)
                    .font(.body)
            }
            .toggleStyle(.checkbox)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

@MainActor
private struct SettingsSection<Content: View>: View {
    let title: String?
    let caption: String?
    let contentSpacing: CGFloat
    private let content: () -> Content

    init(title: String? = nil, caption: String? = nil, contentSpacing: CGFloat = 14, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.caption = caption
        self.contentSpacing = contentSpacing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title, !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            if let caption {
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: self.contentSpacing) {
                self.content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@MainActor
private struct AboutLinkRow: View {
    let icon: String
    let title: String
    let url: String
    @State private var hovering = false

    var body: some View {
        Button {
            if let url = URL(string: self.url) { NSWorkspace.shared.open(url) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: self.icon)
                Text(self.title)
                    .underline(self.hovering, color: .accentColor)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { self.hovering = $0 }
    }
}
