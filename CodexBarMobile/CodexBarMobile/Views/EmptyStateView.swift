import SwiftUI

struct EmptyStateView: View {
    let title: LocalizedStringResource
    let message: LocalizedStringResource
    var systemImage: String = "icloud.and.arrow.down"
    var onDemo: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(self.title)
                    .font(.title2)
                    .fontWeight(.bold)
            } icon: {
                Image(systemName: self.systemImage)
            }
        } description: {
            Text(self.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        } actions: {
            if let onDemo {
                Button(action: onDemo) {
                    Label("View Demo", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}
