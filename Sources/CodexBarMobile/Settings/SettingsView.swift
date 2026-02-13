import CodexBarCore
import SwiftUI

/// Mobile settings view — adapted from the macOS Preferences window.
public struct SettingsView: View {
    @Bindable var store: MobileUsageStore

    public init(store: MobileUsageStore) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("General") {
                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Picker("", selection: $store.refreshIntervalSeconds) {
                        Text("30s").tag(TimeInterval(30))
                        Text("1m").tag(TimeInterval(60))
                        Text("2m").tag(TimeInterval(120))
                        Text("5m").tag(TimeInterval(300))
                    }
                    .pickerStyle(.menu)
                }
            }

            Section("Display") {
                Toggle("Show Desktop-Only Providers", isOn: $store.showDesktopOnlyProviders)
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Platform") {
                    Text(platformName)
                }

                Link("GitHub Repository", destination: URL(string: "https://github.com/o1xhack/CodexBar-Mobile")!)

                Link("Original Project", destination: URL(string: "https://github.com/steipete/CodexBar")!)
            }

            Section {
                LabeledContent("Architecture", value: "Skip Fuse")
                LabeledContent("Core Module", value: "CodexBarCore (Swift)")
            } header: {
                Text("Technical")
            } footer: {
                Text("Built with Skip Framework — Swift code compiled natively for both iOS and Android.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var platformName: String {
        #if os(iOS)
        return "iOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Android"
        #endif
    }
}
