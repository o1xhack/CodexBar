import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "icloud.and.arrow.down")
        } description: {
            Text(message)
        }
    }
}
