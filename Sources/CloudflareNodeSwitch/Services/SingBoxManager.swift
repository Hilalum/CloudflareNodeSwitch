import Foundation

@MainActor
final class SingBoxManager: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var lastError: String?
    @Published private(set) var logTail: String = ""

    private var process: Process?
    private var outputPipe: Pipe?
    private let maxLogLines = 200

    func start(configURL: URL, executablePath: String?) {
        stop()

        guard let executable = resolveExecutable(configuredPath: executablePath) else {
            lastError = "sing-box was not found. Install it with: brew install sing-box"
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["run", "-c", configURL.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        outputPipe = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else {
                return
            }
            Task { @MainActor in
                self?.appendLog(text)
            }
        }

        process.terminationHandler = { [weak self] terminated in
            Task { @MainActor in
                guard let self, self.process === terminated else {
                    return
                }
                self.process = nil
                self.outputPipe?.fileHandleForReading.readabilityHandler = nil
                self.outputPipe = nil
                self.isRunning = false
                if terminated.terminationStatus != 0 {
                    self.lastError = "sing-box exited with code \(terminated.terminationStatus)."
                }
            }
        }

        do {
            try process.run()
            self.process = process
            isRunning = true
            lastError = nil
            appendLog("Started sing-box: \(executable)\n")
        } catch {
            lastError = error.localizedDescription
            isRunning = false
        }
    }

    func stop() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        outputPipe = nil
        if let process, process.isRunning {
            process.terminationHandler = nil
            process.terminate()
        }
        process = nil
        isRunning = false
    }

    func resolveExecutable(configuredPath: String?) -> String? {
        let candidates = [
            configuredPath,
            bundledSingBoxPath(),
            "/opt/homebrew/bin/sing-box",
            "/usr/local/bin/sing-box",
            "/usr/bin/sing-box"
        ].compactMap { $0 }.filter { !$0.isEmpty }

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }

        return runWhich()
    }

    private func bundledSingBoxPath() -> String? {
        guard let url = Bundle.main.url(forResource: "sing-box", withExtension: nil) else {
            return nil
        }
        return url.path
    }

    private func runWhich() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "sing-box"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            return path.isEmpty ? nil : path
        } catch {
            return nil
        }
    }

    private func appendLog(_ text: String) {
        logTail += text
        let lines = logTail.components(separatedBy: .newlines)
        if lines.count > maxLogLines {
            logTail = lines.suffix(maxLogLines).joined(separator: "\n")
        }
    }
}
