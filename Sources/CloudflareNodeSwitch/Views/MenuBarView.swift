import AppKit
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var state: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(LocalizedString.openWindow) {
            if !WindowCoordinator.focusMainWindow() {
                openWindow(id: "main")
                WindowCoordinator.focusMainWindowSoon()
            }
        }

        Divider()

        Button(state.isProxyRunning ? LocalizedString.stopProxy : LocalizedString.startProxy) {
            if state.isProxyRunning {
                state.stopProxy()
            } else {
                state.startProxyFromUI()
            }
        }
        .disabled(state.nodes.isEmpty)

        Toggle(isOn: Binding(
            get: { state.isProxyRunning ? state.isIntegratedProxyEnabled : state.shouldAutoEnableIntegration },
            set: { state.setIntegratedProxyEnabled($0) }
        )) {
            Label(LocalizedString.integration, systemImage: "network")
        }

        Menu(LocalizedString.openProxied) {
            Button(LocalizedString.terminal) {
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

        Button(LocalizedString.refreshSubscription) {
            state.refreshSubscription()
        }
        .disabled(state.isRefreshing)

        Divider()

        Button(LocalizedString.quit) {
            NSApp.terminate(nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            state.shutdown()
        }
    }

}
