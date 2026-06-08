import Foundation

enum SingBoxConfigError: LocalizedError {
    case emptyNodeList
    case selectedNodeMissing

    var errorDescription: String? {
        switch self {
        case .emptyNodeList:
            return "No nodes are available for sing-box config generation."
        case .selectedNodeMissing:
            return "The selected node is no longer available."
        }
    }
}

struct SingBoxConfigBuilder {
    var localPort: Int
    var clashAPIPort: Int = 19090
    var testURL: String = "https://www.gstatic.com/generate_204"
    var testInterval: String = "1m"
    var tolerance: Int = 50

    func build(nodes: [ProxyNode], mode: ProxyMode) throws -> Data {
        guard !nodes.isEmpty else {
            throw SingBoxConfigError.emptyNodeList
        }

        let nodeTags = nodes.indices.map { "node-\($0 + 1)" }
        let finalTag: String
        switch mode {
        case .auto:
            finalTag = "auto"
        case .manual(let id):
            guard let index = nodes.firstIndex(where: { $0.id == id }) else {
                throw SingBoxConfigError.selectedNodeMissing
            }
            finalTag = nodeTags[index]
        }

        let config = SingBoxConfig(
            experimental: ExperimentalConfig(
                clashAPI: ClashAPIConfig(externalController: "127.0.0.1:\(clashAPIPort)")
            ),
            log: LogConfig(level: "warn", timestamp: true),
            inbounds: [
                InboundConfig(
                    type: "mixed",
                    tag: "mixed-in",
                    listen: "127.0.0.1",
                    listenPort: localPort
                )
            ],
            outbounds: [
                AnyEncodable(UrlTestOutbound(
                    type: "urltest",
                    tag: "auto",
                    outbounds: nodeTags,
                    url: testURL,
                    interval: testInterval,
                    tolerance: tolerance
                )),
                AnyEncodable(DirectOutbound(type: "direct", tag: "direct"))
            ] + zip(nodes, nodeTags).map { node, tag in
                AnyEncodable(buildVLESSOutbound(node: node, tag: tag))
            },
            route: RouteConfig(
                autoDetectInterface: true,
                rules: [
                    RouteRule(inbound: "mixed-in", action: "sniff")
                ],
                final: finalTag
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(config)
    }

    private func buildVLESSOutbound(node: ProxyNode, tag: String) -> VLESSOutbound {
        let tls: TLSConfig?
        if node.security.lowercased() == "tls" {
            tls = TLSConfig(
                enabled: true,
                serverName: node.sni,
                insecure: node.allowInsecure,
                utls: UTLSConfig.from(fingerprint: node.fingerprint)
            )
        } else {
            tls = nil
        }

        let transport: TransportConfig?
        if node.network.lowercased() == "ws" {
            var headers: [String: String] = [:]
            if let host = node.host, !host.isEmpty {
                headers["Host"] = host
            }
            transport = TransportConfig(
                type: "ws",
                path: node.path?.isEmpty == false ? node.path : "/",
                headers: headers.isEmpty ? nil : headers
            )
        } else {
            transport = nil
        }

        return VLESSOutbound(
            type: "vless",
            tag: tag,
            server: node.server,
            serverPort: node.port,
            uuid: node.uuid,
            tls: tls,
            transport: transport
        )
    }
}

private struct SingBoxConfig: Encodable {
    let experimental: ExperimentalConfig
    let log: LogConfig
    let inbounds: [InboundConfig]
    let outbounds: [AnyEncodable]
    let route: RouteConfig
}

private struct ExperimentalConfig: Encodable {
    let clashAPI: ClashAPIConfig

    enum CodingKeys: String, CodingKey {
        case clashAPI = "clash_api"
    }
}

private struct ClashAPIConfig: Encodable {
    let externalController: String

    enum CodingKeys: String, CodingKey {
        case externalController = "external_controller"
    }
}

private struct LogConfig: Encodable {
    let level: String
    let timestamp: Bool
}

private struct InboundConfig: Encodable {
    let type: String
    let tag: String
    let listen: String
    let listenPort: Int

    enum CodingKeys: String, CodingKey {
        case type
        case tag
        case listen
        case listenPort = "listen_port"
    }
}

private struct DirectOutbound: Encodable {
    let type: String
    let tag: String
}

private struct UrlTestOutbound: Encodable {
    let type: String
    let tag: String
    let outbounds: [String]
    let url: String
    let interval: String
    let tolerance: Int
}

private struct VLESSOutbound: Encodable {
    let type: String
    let tag: String
    let server: String
    let serverPort: Int
    let uuid: String
    let tls: TLSConfig?
    let transport: TransportConfig?

    enum CodingKeys: String, CodingKey {
        case type
        case tag
        case server
        case serverPort = "server_port"
        case uuid
        case tls
        case transport
    }
}

private struct TLSConfig: Encodable {
    let enabled: Bool
    let serverName: String?
    let insecure: Bool
    let utls: UTLSConfig?

    enum CodingKeys: String, CodingKey {
        case enabled
        case serverName = "server_name"
        case insecure
        case utls
    }
}

private struct UTLSConfig: Encodable {
    let enabled: Bool
    let fingerprint: String

    static func from(fingerprint: String?) -> UTLSConfig? {
        guard let fingerprint, !fingerprint.isEmpty else {
            return nil
        }
        return UTLSConfig(enabled: true, fingerprint: fingerprint)
    }
}

private struct TransportConfig: Encodable {
    let type: String
    let path: String?
    let headers: [String: String]?
}

private struct RouteConfig: Encodable {
    let autoDetectInterface: Bool
    let rules: [RouteRule]
    let final: String

    enum CodingKeys: String, CodingKey {
        case autoDetectInterface = "auto_detect_interface"
        case rules
        case final
    }
}

private struct RouteRule: Encodable {
    let inbound: String
    let action: String
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        self.encodeValue = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
