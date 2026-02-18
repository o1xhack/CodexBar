import CodexBarSync
import SwiftUI

/// A SwiftUI view modifier that starts the iCloud sync coordinator.
///
/// Applied in `CodexBarApp.body` to the hidden keepalive window so that
/// usage data is continuously pushed to iCloud for the iOS companion app.
struct CloudSyncModifier: ViewModifier {
    let store: UsageStore
    @State private var coordinator: SyncCoordinator?

    func body(content: Content) -> some View {
        content
            .onAppear {
                let coord = SyncCoordinator(store: self.store)
                coord.startObserving()
                self.coordinator = coord
            }
            .onDisappear {
                self.coordinator?.stopObserving()
            }
    }
}
