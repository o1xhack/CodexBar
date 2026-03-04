import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "icloud.and.arrow.down"
    var onDemo: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(self.title, systemImage: self.systemImage)
                .font(.title2)
                .fontWeight(.bold)
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
