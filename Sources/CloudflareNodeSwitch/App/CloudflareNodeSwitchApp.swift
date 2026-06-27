import AppKit
import SwiftUI

@main
struct CloudflareNodeSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup(LocalizedString.appTitle, id: "main") {
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
                Button(LocalizedString.refreshSubscription) {
                    state.refreshSubscription()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button(state.isProxyRunning ? LocalizedString.stopProxy : LocalizedString.startProxy) {
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
            Label(LocalizedString.appTitle, systemImage: state.isProxyRunning ? "bolt.horizontal.fill" : "bolt.horizontal")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        state?.shutdown()
    }
}
