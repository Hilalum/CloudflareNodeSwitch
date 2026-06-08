import AppKit
import SwiftUI

@main
struct CloudflareNodeSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup("Cloudflare Node Switch", id: "main") {
            ContentView(state: state)
                .frame(minWidth: 880, minHeight: 560)
                .onAppear {
                    appDelegate.state = state
                    state.refreshOnLaunchIfNeeded()
                    WindowCoordinator.focusMainWindowSoon()
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Refresh Subscription") {
                    state.refreshSubscription()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button(state.isProxyRunning ? "Stop Proxy" : "Start Proxy") {
                    if state.isProxyRunning {
                        state.stopProxy()
                    } else {
                        state.startProxyFromUI()
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        MenuBarExtra {
            MenuBarView(state: state)
        } label: {
            Label("Node Switch", systemImage: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        state?.shutdown()
    }
}
