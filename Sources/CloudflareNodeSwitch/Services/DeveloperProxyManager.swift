import Foundation

struct DeveloperProxyManager {
    private let beginMarker = "# >>> CloudflareNodeSwitch proxy >>>"
    private let endMarker = "# <<< CloudflareNodeSwitch proxy <<<"

    func enable(host: String, port: Int) throws {
        let httpProxy = "http://\(host):\(port)"
        let socksProxy = "socks5://\(host):\(port)"
        let noProxy = "localhost,127.0.0.1,::1"

        try setLaunchEnvironment([
            "HTTP_PROXY": httpProxy,
            "HTTPS_PROXY": httpProxy,
            "ALL_PROXY": socksProxy,
            "NO_PROXY": noProxy,
            "http_proxy": httpProxy,
            "https_proxy": httpProxy,
            "all_proxy": socksProxy,
            "no_proxy": noProxy
        ])

        let block = """
        \(beginMarker)
        export HTTP_PROXY=\(httpProxy)
        export HTTPS_PROXY=\(httpProxy)
        export ALL_PROXY=\(socksProxy)
        export NO_PROXY=\(noProxy)
        export http_proxy=$HTTP_PROXY
        export https_proxy=$HTTPS_PROXY
        export all_proxy=$ALL_PROXY
        export no_proxy=$NO_PROXY
        \(endMarker)
        """

        try updateShellProfiles(
            block: """
            \(block)
            """
        )
    }

    func disable() throws {
        try unsetLaunchEnvironment(["HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY", "http_proxy", "https_proxy", "all_proxy", "no_proxy"])
        try updateShellProfiles(block: nil)
    }

    func openProxiedTerminal(host: String, port: Int, command: String?) throws {
        let script = terminalScript(host: host, port: port, command: command)
        let escapedScript = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapedScript)"
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        let errorOutput = Pipe()
        process.standardError = errorOutput

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(decoding: errorOutput.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw NSError(
                domain: "DeveloperProxyManager",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "Failed to open Terminal." : message]
            )
        }
    }

    private func terminalScript(host: String, port: Int, command: String?) -> String {
        let httpProxy = "http://\(host):\(port)"
        let socksProxy = "socks5://\(host):\(port)"
        let noProxy = "localhost,127.0.0.1,::1"
        let exports = """
        export HTTP_PROXY='\(httpProxy)'
        export HTTPS_PROXY='\(httpProxy)'
        export ALL_PROXY='\(socksProxy)'
        export NO_PROXY='\(noProxy)'
        export http_proxy="$HTTP_PROXY"
        export https_proxy="$HTTPS_PROXY"
        export all_proxy="$ALL_PROXY"
        export no_proxy="$NO_PROXY"
        """

        guard let command, !command.isEmpty else {
            return """
            \(exports)
            echo 'Cloudflare Node Switch proxy is active for this Terminal.'
            exec zsh
            """
        }

        return """
        \(exports)
        if command -v \(command) >/dev/null 2>&1; then
          exec \(command)
        else
          echo '\(command) was not found in PATH. Proxy variables are active in this Terminal.'
          exec zsh
        fi
        """
    }

    private func updateShellProfiles(block: String?) throws {
        for filename in [".zshrc", ".zprofile"] {
            let profileURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(filename)
            try updateShellProfile(profileURL: profileURL, block: block)
        }
    }

    private func updateShellProfile(profileURL: URL, block: String?) throws {
        let existing = (try? String(contentsOf: profileURL, encoding: .utf8)) ?? ""
        let cleaned = removeManagedBlock(from: existing)

        let next: String
        if let block {
            var text = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                text += "\n\n"
            }
            next = text + block + "\n"
        } else {
            next = cleaned.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }

        try next.write(to: profileURL, atomically: true, encoding: .utf8)
    }

    private func removeManagedBlock(from text: String) -> String {
        guard let start = text.range(of: beginMarker),
              let end = text.range(of: endMarker, range: start.lowerBound..<text.endIndex) else {
            return text
        }

        var result = text
        result.removeSubrange(start.lowerBound..<end.upperBound)
        return result
    }

    private func setLaunchEnvironment(_ values: [String: String]) throws {
        for (key, value) in values {
            try runLaunchctl(["setenv", key, value])
        }
    }

    private func unsetLaunchEnvironment(_ keys: [String]) throws {
        for key in keys {
            try runLaunchctl(["unsetenv", key])
        }
    }

    private func runLaunchctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let errorOutput = Pipe()
        process.standardError = errorOutput

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(decoding: errorOutput.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw NSError(
                domain: "DeveloperProxyManager",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message.isEmpty ? "launchctl failed." : message]
            )
        }
    }
}
