import SwiftUI

struct OnboardingView: View {
    var onDemo: (() -> Void)?

    private let steps: [(icon: String, title: String, detail: String)] = [
        ("laptopcomputer.and.arrow.down", "Install CodexBar on Mac", "Download from the GitHub release page and move to Applications."),
        ("gearshape", "Enable iCloud Sync", "Open CodexBar on your Mac → Settings → turn on iCloud Sync."),
        ("icloud.and.arrow.up", "Wait for Sync", "Usage data will appear here automatically once your Mac pushes data to iCloud."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)

                    Text("Welcome to CodexBar")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Monitor your AI coding tool usage on iPhone.\nRequires the CodexBar Mac app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                // Steps
                VStack(spacing: 20) {
                    ForEach(Array(self.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.tint.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: step.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.tint)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step \(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                                Text(step.title)
                                    .font(.headline)
                                Text(step.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Actions
                VStack(spacing: 12) {
                    Link(destination: URL(string: "https://github.com/o1xhack/CodexBar/releases")!) {
                        Label("Download Mac App", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if let onDemo {
                        Button(action: onDemo) {
                            Label("Preview with Demo Data", systemImage: "play.fill")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView(onDemo: {})
}
