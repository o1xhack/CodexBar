import CodexBarCore
import SwiftUI

/// Displays a provider's icon using SF Symbols.
/// On macOS the app uses a custom IconRenderer; on mobile we use
/// simpler SF Symbol representations.
struct ProviderIconView: View {
    let provider: UsageProvider

    var body: some View {
        Image(systemName: symbolName)
            .font(.title3)
            .foregroundStyle(symbolColor)
            .frame(width: 28, height: 28)
    }

    private var symbolName: String {
        switch provider {
        case .claude: "brain.head.profile"
        case .codex: "terminal"
        case .cursor: "cursorarrow.rays"
        case .copilot: "airplane"
        case .gemini: "sparkles"
        case .zai: "bolt.fill"
        case .minimax: "waveform"
        case .kimi, .kimik2: "globe.asia.australia.fill"
        case .kiro: "arrow.triangle.branch"
        case .vertexai: "cloud.fill"
        case .augment: "plus.circle.fill"
        case .amp: "bolt.circle.fill"
        case .jetbrains: "hammer.fill"
        case .opencode: "chevron.left.forwardslash.chevron.right"
        case .factory: "gearshape.2.fill"
        case .antigravity: "arrow.up.circle.fill"
        case .synthetic: "cpu"
        case .warp: "rectangle.split.3x3.fill"
        }
    }

    private var symbolColor: Color {
        switch provider {
        case .claude: .orange
        case .codex: .green
        case .cursor: .blue
        case .copilot: .indigo
        case .gemini: .blue
        case .zai: .purple
        case .minimax: .teal
        case .kimi, .kimik2: .cyan
        case .kiro: .mint
        case .vertexai: .blue
        case .augment: .green
        case .amp: .yellow
        case .jetbrains: .pink
        case .opencode: .gray
        case .factory: .brown
        case .antigravity: .red
        case .synthetic: .gray
        case .warp: .orange
        }
    }
}
