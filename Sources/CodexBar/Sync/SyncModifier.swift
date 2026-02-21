import CodexBarSync
import SwiftUI

/// A SwiftUI view modifier that starts the iCloud sync coordinator.
///
/// Applied in `CodexBarApp.body` to the hidden keepalive window so that
/// usage data is continuously pushed to iCloud for the iOS companion app.
struct CloudSyncModifier: ViewModifier {
    let coordinator: SyncCoordinator

    func body(content: Content) -> some View {
        content
            .onAppear {
                self.coordinator.startObserving()
            }
            .onDisappear {
                self.coordinator.stopObserving()
            }
    }
}
