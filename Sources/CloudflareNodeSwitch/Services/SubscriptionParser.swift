import Foundation

enum SubscriptionParserError: LocalizedError {
    case noSupportedNodes

    var errorDescription: String? {
        switch self {
        case .noSupportedNodes:
            return LocalizedString.noSupportedNodes
        }
    }
}

struct SubscriptionParser {
    func parse(_ rawText: String) throws -> [ProxyNode] {
        let text = decodeIfNeeded(rawText.trimmingCharacters(in: .whitespacesAndNewlines))
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var nodes: [ProxyNode] = []
        for line in lines where line.lowercased().hasPrefix("vless://") {
            if let node = parseVLESS(line) {
                nodes.append(node)
            }
        }

        guard !nodes.isEmpty else {
            throw SubscriptionParserError.noSupportedNodes
        }

        return uniqued(nodes)
    }

    private func decodeIfNeeded(_ text: String) -> String {
        if text.lowercased().contains("vless://") {
            return text
        }

        let normalized = text
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingCount = (4 - normalized.count % 4) % 4
        let padded = normalized + String(repeating: "=", count: paddingCount)

        guard let data = Data(base64Encoded: padded),
              let decoded = String(data: data, encoding: .utf8) else {
            return text
        }

        return decoded
    }

    private func parseVLESS(_ line: String) -> ProxyNode? {
        guard let url = URLComponents(string: line),
              let uuid = url.user,
              let server = url.host,
              let port = url.port else {
            return nil
        }

        var query: [String: String] = [:]
        for item in url.queryItems ?? [] {
            query[item.name] = item.value ?? ""
        }

        let fragment = url.percentEncodedFragment ?? url.fragment ?? ""
        let name = fragment.removingPercentEncoding ?? fragment

        return ProxyNode(
            name: name,
            uuid: uuid,
            server: server,
            port: port,
            encryption: query["encryption"] ?? "none",
            security: query["security"] ?? "none",
            network: query["type"] ?? "tcp",
            host: query["host"],
            path: query["path"],
            sni: query["sni"],
            fingerprint: query["fp"],
            allowInsecure: query["allowInsecure"] == "1" || query["allowInsecure"]?.lowercased() == "true",
            rawURL: line
        )
    }

    private func uniqued(_ nodes: [ProxyNode]) -> [ProxyNode] {
        var seen: [String: Int] = [:]
        return nodes.enumerated().map { index, node in
            var copy = node
            let baseName = copy.displayName
            let occurrence = seen[baseName, default: 0] + 1
            seen[baseName] = occurrence
            if occurrence > 1 {
                copy.name = "\(baseName) \(occurrence)"
            }
            if copy.name.isEmpty {
                copy.name = String(format: LocalizedString.nodeFallback, index + 1)
            }
            return copy
        }
    }
}
