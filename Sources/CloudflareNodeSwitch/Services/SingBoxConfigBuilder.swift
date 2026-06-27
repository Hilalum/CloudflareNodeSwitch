import Foundation

enum SingBoxConfigError: LocalizedError {
    case emptyNodeList
    case selectedNodeMissing

    var errorDescription: String? {
        switch self {
        case .emptyNodeList:
            return LocalizedString.noNodesAvailable
        case .selectedNodeMissing:
            return LocalizedString.selectedNodeMissing
        }
    }
}

struct SingBoxConfigBuilder {
    var localPort: Int
    var clashAPIPort: Int = SingBoxConfigBuilder.defaultClashAPIPort
    var testURL: String = "https://www.gstatic.com/generate_204"
    var testInterval: String = "3m"
    var tolerance: Int = SingBoxConfigBuilder.autoSelectionTolerance

    static let defaultClashAPIPort = 19090
    static let autoSelectionTolerance = 0

    func build(nodes: [ProxyNode], mode: ProxyMode, routingMode: RoutingMode = .aiStable, inboundMode: InboundMode = .mixed) throws -> Data {
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

        let inboundTag: String
        let inbounds: [AnyEncodable]
        switch inboundMode {
        case .mixed:
            inboundTag = "mixed-in"
            inbounds = [
                AnyEncodable(InboundConfig(
                    type: "mixed",
                    tag: "mixed-in",
                    listen: "127.0.0.1",
                    listenPort: localPort
                ))
            ]
        case .tun:
            inboundTag = "tun-in"
            inbounds = [
                AnyEncodable(TunInboundConfig(
                    type: "tun",
                    tag: "tun-in",
                    interfaceName: "utun10",
                    address: ["172.19.0.1/30"],
                    autoRoute: true,
                    strictRoute: false,
                    stack: "system"
                ))
            ]
        }

        // TUN 模式需要 DNS 配置，否则 DNS 解析会失败
        let dns: DNSConfig? = inboundMode == .tun ? DNSConfig(
            servers: [
                DNSServer(type: "https", tag: "dns-direct", server: "dns.google", path: "/dns-query", detour: "direct"),
                DNSServer(type: "https", tag: "dns-proxy", server: "cloudflare-dns.com", path: "/dns-query", detour: finalTag)
            ]
        ) : nil

        let config = SingBoxConfig(
            experimental: ExperimentalConfig(
                clashAPI: ClashAPIConfig(externalController: "127.0.0.1:\(clashAPIPort)")
            ),
            log: LogConfig(level: "warn", timestamp: true),
            dns: dns,
            inbounds: inbounds,
            outbounds: [
                AnyEncodable(UrlTestOutbound(
                    type: "urltest",
                    tag: "auto",
                    outbounds: nodeTags,
                    url: urlTestURL(for: routingMode),
                    interval: urlTestInterval(for: routingMode),
                    tolerance: tolerance,
                    idleTimeout: "30m",
                    interruptExistConnections: false
                )),
                AnyEncodable(DirectOutbound(type: "direct", tag: "direct"))
            ] + zip(nodes, nodeTags).map { node, tag in
                AnyEncodable(buildVLESSOutbound(node: node, tag: tag))
            },
            route: RouteConfig(
                autoDetectInterface: true,
                defaultDomainResolver: inboundMode == .tun ? "dns-direct" : nil,
                rules: routeRules(for: routingMode, proxyOutbound: finalTag, inboundTag: inboundTag),
                final: finalTag
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(config)
    }

    private func urlTestURL(for routingMode: RoutingMode) -> String {
        switch routingMode {
        case .global, .smartCN:
            return testURL
        case .aiStable:
            return "https://api.anthropic.com/v1/messages"
        }
    }

    private func urlTestInterval(for routingMode: RoutingMode) -> String {
        switch routingMode {
        case .global, .smartCN:
            return testInterval
        case .aiStable:
            return "5m"
        }
    }

    private func routeRules(for routingMode: RoutingMode, proxyOutbound: String, inboundTag: String) -> [RouteRule] {
        var rules: [RouteRule] = [
            RouteRule(inbound: inboundTag, action: "sniff"),
            localDirectRule()
        ]

        switch routingMode {
        case .global:
            break
        case .smartCN:
            rules.append(cnDirectRule())
        case .aiStable:
            rules.append(aiProxyRule(outbound: proxyOutbound))
            rules.append(cnDirectRule())
        }

        return rules
    }

    private func localDirectRule() -> RouteRule {
        RouteRule(
            domainSuffix: ["local", "localhost"],
            ipIsPrivate: true,
            action: "route",
            outbound: "direct"
        )
    }

    private func cnDirectRule() -> RouteRule {
        RouteRule(
            domainSuffix: [
                "cn", "com.cn", "net.cn", "org.cn", "gov.cn", "edu.cn",
                "中国", "公司", "网络",
                "baidu.com", "bdstatic.com", "bilibili.com", "biliapi.net",
                "qq.com", "gtimg.com", "qpic.cn", "wechat.com", "weixin.qq.com",
                "taobao.com", "tmall.com", "alicdn.com", "aliyun.com", "alipay.com",
                "jd.com", "360buyimg.com", "douyin.com", "snssdk.com",
                "163.com", "126.com", "sina.com.cn", "weibo.com",
                "zhihu.com", "xiaohongshu.com", "meituan.com", "amap.com",
                "mi.com", "xiaomi.com", "huawei.com", "bytedance.com"
            ],
            action: "route",
            outbound: "direct"
        )
    }

    private func aiProxyRule(outbound: String) -> RouteRule {
        RouteRule(
            domainSuffix: [
                "openai.com", "chatgpt.com", "oaistatic.com", "oaiusercontent.com",
                "anthropic.com", "claude.ai",
                "gemini.google.com", "bard.google.com", "aistudio.google.com",
                "google.com", "google.com.hk", "google.com.tw", "google.co.jp",
                "googleapis.com", "generativelanguage.googleapis.com",
                "apis.google.com", "clients6.google.com", "ogs.google.com",
                "gstatic.com", "ssl.gstatic.com", "googleusercontent.com",
                "accounts.google.com", "withgoogle.com", "recaptcha.net",
                "gvt1.com", "gvt2.com", "gvt3.com",
                "doubleclick.net", "googletagmanager.com", "google-analytics.com",
                "github.com", "githubusercontent.com", "githubassets.com",
                "githubcopilot.com", "github.dev",
                "npmjs.com", "registry.npmjs.org"
            ],
            action: "route",
            outbound: outbound
        )
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
    let dns: DNSConfig?
    let inbounds: [AnyEncodable]
    let outbounds: [AnyEncodable]
    let route: RouteConfig
}

private struct DNSConfig: Encodable {
    let servers: [DNSServer]
}

private struct DNSServer: Encodable {
    let type: String
    let tag: String
    let server: String
    let path: String
    let detour: String
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

private struct TunInboundConfig: Encodable {
    let type: String
    let tag: String
    let interfaceName: String
    let address: [String]
    let autoRoute: Bool
    let strictRoute: Bool
    let stack: String

    enum CodingKeys: String, CodingKey {
        case type
        case tag
        case interfaceName = "interface_name"
        case address
        case autoRoute = "auto_route"
        case strictRoute = "strict_route"
        case stack
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
    let idleTimeout: String
    let interruptExistConnections: Bool

    enum CodingKeys: String, CodingKey {
        case type
        case tag
        case outbounds
        case url
        case interval
        case tolerance
        case idleTimeout = "idle_timeout"
        case interruptExistConnections = "interrupt_exist_connections"
    }
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
    let defaultDomainResolver: String?
    let rules: [RouteRule]
    let final: String

    enum CodingKeys: String, CodingKey {
        case autoDetectInterface = "auto_detect_interface"
        case defaultDomainResolver = "default_domain_resolver"
        case rules
        case final
    }
}

private struct RouteRule: Encodable {
    var inbound: String?
    var domain: [String]?
    var domainSuffix: [String]?
    var domainKeyword: [String]?
    var ipIsPrivate: Bool?
    let action: String
    var outbound: String?

    init(
        inbound: String? = nil,
        domain: [String]? = nil,
        domainSuffix: [String]? = nil,
        domainKeyword: [String]? = nil,
        ipIsPrivate: Bool? = nil,
        action: String,
        outbound: String? = nil
    ) {
        self.inbound = inbound
        self.domain = domain
        self.domainSuffix = domainSuffix
        self.domainKeyword = domainKeyword
        self.ipIsPrivate = ipIsPrivate
        self.action = action
        self.outbound = outbound
    }

    enum CodingKeys: String, CodingKey {
        case inbound
        case domain
        case domainSuffix = "domain_suffix"
        case domainKeyword = "domain_keyword"
        case ipIsPrivate = "ip_is_private"
        case action
        case outbound
    }
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
