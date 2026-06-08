import Foundation

struct SystemProxyManager {
    func enable(host: String, port: Int) throws {
        let services = try networkServices()
        for service in services {
            try runNetworkSetup(["-setwebproxy", service, host, "\(port)"])
            try runNetworkSetup(["-setsecurewebproxy", service, host, "\(port)"])
            try runNetworkSetup(["-setsocksfirewallproxy", service, host, "\(port)"])
            try runNetworkSetup(["-setwebproxystate", service, "on"])
            try runNetworkSetup(["-setsecurewebproxystate", service, "on"])
            try runNetworkSetup(["-setsocksfirewallproxystate", service, "on"])
        }
    }

    func disable() throws {
        let services = try networkServices()
        for service in services {
            try runNetworkSetup(["-setwebproxystate", service, "off"])
            try runNetworkSetup(["-setsecurewebproxystate", service, "off"])
            try runNetworkSetup(["-setsocksfirewallproxystate", service, "off"])
        }
    }

    private func networkServices() throws -> [String] {
        let output = try runNetworkSetup(["-listallnetworkservices"])
        return output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { !$0.hasPrefix("An asterisk") }
            .filter { !$0.hasPrefix("*") }
    }

    @discardableResult
    private func runNetworkSetup(_ arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments

        let output = Pipe()
        let errorOutput = Pipe()
        process.standardOutput = output
        process.standardError = errorOutput

        try process.run()
        process.waitUntilExit()

        let outputText = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        let errorText = String(decoding: errorOutput.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "SystemProxyManager",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorText.isEmpty ? outputText : errorText]
            )
        }

        return outputText
    }
}
