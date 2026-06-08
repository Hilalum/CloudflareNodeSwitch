import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Window") {
            if !WindowCoordinator.focusMainWindow() {
                openWindow(id: "main")
                WindowCoordinator.focusMainWindowSoon()
            }
        }

        Divider()

        Text(state.isProxyRunning ? "Running - \(state.modeDisplayName)" : "Stopped")
        if state.isProxyRunning {
            Text("Current: \(state.currentNodeName)")
        }

        Button(state.isProxyRunning ? "Stop Proxy" : "Start Proxy") {
            if state.isProxyRunning {
                state.stopProxy()
            } else {
                state.startProxyFromUI()
            }
        }
        .disabled(state.nodes.isEmpty)

        Button("Refresh Subscription") {
            state.refreshSubscription()
        }
        .disabled(state.isRefreshing)

        Button("Test Latency") {
            state.testLatencies()
        }
        .disabled(state.isTesting || state.nodes.isEmpty)

        Toggle(isOn: Binding(
            get: { state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration },
            set: { state.setIntegratedProxyEnabled($0) }
        )) {
            Label("Integration", systemImage: "network")
        }

        Menu("Open Proxied") {
            Button("Terminal") {
                state.openProxiedTerminal(command: nil)
            }

            Button("Codex") {
                state.openProxiedTerminal(command: "codex")
            }

            Button("Claude") {
                state.openProxiedTerminal(command: "claude")
            }
        }
        .disabled(!state.isProxyRunning)

        Divider()

        Button("Auto Select") {
            state.chooseAuto()
        }

        ForEach(state.sortedNodes.prefix(8)) { node in
            Button(shortTitle(node.displayName)) {
                state.choose(node: node)
            }
        }

        Divider()

        Text(state.statusMessage)
        Button("Quit") {
            NSApp.terminate(nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            state.shutdown()
        }
    }

    private func shortTitle(_ value: String) -> String {
        if value.count <= 30 {
            return value
        }
        return String(value.prefix(27)) + "..."
    }
}
