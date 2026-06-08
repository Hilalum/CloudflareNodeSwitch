import AppKit

@MainActor
enum WindowCoordinator {
    private static let mainWindowTitle = "Cloudflare Node Switch"

    @discardableResult
    static func focusMainWindow() -> Bool {
        let windows = NSApp.windows
            .filter { $0.title == mainWindowTitle && $0.canBecomeMain }

        guard let window = windows.first else {
            return false
        }

        for duplicate in windows.dropFirst() {
            duplicate.close()
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        return true
    }

    static func focusMainWindowSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            focusMainWindow()
        }
    }
}
