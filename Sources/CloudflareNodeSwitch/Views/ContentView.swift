import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState
    @State private var selectedNodeID: ProxyNode.ID?

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(state: state, selectedNodeID: $selectedNodeID)
                .frame(width: 300)

            Divider()

            DetailView(state: state, selectedNodeID: selectedNodeID)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            state.shutdown()
        }
    }
}
