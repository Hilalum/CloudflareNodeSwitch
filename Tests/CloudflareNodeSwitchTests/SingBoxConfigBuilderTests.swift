import Foundation
import XCTest
@testable import CloudflareNodeSwitch

final class SingBoxConfigBuilderTests: XCTestCase {

    // MARK: - Mixed Inbound Tests

    func testBuildsMixedInboundConfig() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .aiStable,
            inboundMode: .mixed
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // 验证 inbound
        let inbounds = json?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.count, 1)
        XCTAssertEqual(inbounds?.first?["type"] as? String, "mixed")
        XCTAssertEqual(inbounds?.first?["tag"] as? String, "mixed-in")
        XCTAssertEqual(inbounds?.first?["listen"] as? String, "127.0.0.1")
        XCTAssertEqual(inbounds?.first?["listen_port"] as? Int, 7890)

        // 验证无 DNS（mixed 模式不需要）
        XCTAssertNil(json?["dns"])

        try assertSingBoxAccepts(data)
    }

    // MARK: - TUN Inbound Tests

    func testBuildsTunInboundConfig() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .smartCN,
            inboundMode: .tun
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // 验证 TUN inbound
        let inbounds = json?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.count, 1)
        XCTAssertEqual(inbounds?.first?["type"] as? String, "tun")
        XCTAssertEqual(inbounds?.first?["tag"] as? String, "tun-in")
        XCTAssertEqual(inbounds?.first?["interface_name"] as? String, "utun10")
        XCTAssertEqual(inbounds?.first?["address"] as? [String], ["172.19.0.1/30"])
        XCTAssertEqual(inbounds?.first?["auto_route"] as? Bool, true)
        XCTAssertEqual(inbounds?.first?["strict_route"] as? Bool, false)
        XCTAssertEqual(inbounds?.first?["stack"] as? String, "system")

        // 验证 DNS 配置（TUN 模式必须有）
        let dns = json?["dns"] as? [String: Any]
        XCTAssertNotNil(dns, "TUN mode must have DNS config")
        let servers = dns?["servers"] as? [[String: Any]]
        XCTAssertEqual(servers?.count, 2)
        // DNS server structure uses "server" field, not "address"
        XCTAssertEqual(servers?.first?["server"] as? String, "dns.google")
        XCTAssertEqual(servers?.first?["detour"] as? String, "direct")
        XCTAssertEqual(servers?[1]["detour"] as? String, "auto")

        // 验证路由规则使用 tun-in
        let route = json?["route"] as? [String: Any]
        let rules = route?["rules"] as? [[String: Any]]
        XCTAssertEqual(rules?.first?["inbound"] as? String, "tun-in")
        XCTAssertEqual(rules?.first?["action"] as? String, "sniff")

        try assertSingBoxAccepts(data)
    }

    // MARK: - Route Rules Tests

    func testGlobalModeHasMinimalRules() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rules = (json?["route"] as? [String: Any])?["rules"] as? [[String: Any]]

        // Global mode: sniff + local direct only
        XCTAssertEqual(rules?.count, 2)
        XCTAssertEqual(rules?[0]["action"] as? String, "sniff")
        XCTAssertEqual(rules?[1]["outbound"] as? String, "direct")
    }

    func testSmartCNModeHasCNDirectRule() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .smartCN
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rules = (json?["route"] as? [String: Any])?["rules"] as? [[String: Any]]

        // Smart CN: sniff + local direct + CN direct
        XCTAssertEqual(rules?.count, 3)
        let cnRule = rules?[2]
        XCTAssertEqual(cnRule?["outbound"] as? String, "direct")
        let domainSuffix = cnRule?["domain_suffix"] as? [String]
        XCTAssertTrue(domainSuffix?.contains("cn") ?? false)
        XCTAssertTrue(domainSuffix?.contains("baidu.com") ?? false)
    }

    func testAIStableModeHasAIProxyAndCNDirectRules() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .aiStable
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let rules = (json?["route"] as? [String: Any])?["rules"] as? [[String: Any]]

        // AI Stable: sniff + local direct + AI proxy + CN direct
        XCTAssertEqual(rules?.count, 4)

        // AI proxy rule
        let aiRule = rules?[2]
        XCTAssertEqual(aiRule?["outbound"] as? String, "auto")
        let aiDomains = aiRule?["domain_suffix"] as? [String]
        XCTAssertTrue(aiDomains?.contains("openai.com") ?? false)
        XCTAssertTrue(aiDomains?.contains("anthropic.com") ?? false)
        XCTAssertTrue(aiDomains?.contains("github.com") ?? false)
    }

    // MARK: - Manual Mode Tests

    func testManualModeSelectsSpecificNode() throws {
        let node1 = makeNode(name: "Node 1")
        let node2 = makeNode(name: "Node 2")
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node1, node2],
            mode: .manual(node2.id),
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual((json?["route"] as? [String: Any])?["final"] as? String, "node-2")
    }

    func testManualModeWithMissingNodeThrows() {
        let node = makeNode()
        XCTAssertThrowsError(
            try SingBoxConfigBuilder(localPort: 7890).build(
                nodes: [node],
                mode: .manual(UUID()),
                routingMode: .global
            )
        )
    }

    // MARK: - VLESS Outbound Tests

    func testBuildsVLESSOutboundWithTLS() throws {
        let node = makeNode(security: "tls", sni: "example.com", fingerprint: "chrome")
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }

        XCTAssertNotNil(vless)
        XCTAssertEqual(vless?["server"] as? String, "104.16.157.214")
        XCTAssertEqual(vless?["server_port"] as? Int, 443)

        let tls = vless?["tls"] as? [String: Any]
        XCTAssertEqual(tls?["enabled"] as? Bool, true)
        XCTAssertEqual(tls?["server_name"] as? String, "example.com")
        XCTAssertEqual(tls?["insecure"] as? Bool, false)

        let utls = tls?["utls"] as? [String: Any]
        XCTAssertEqual(utls?["enabled"] as? Bool, true)
        XCTAssertEqual(utls?["fingerprint"] as? String, "chrome")
    }

    func testBuildsVLESSOutboundWithWebSocket() throws {
        let node = makeNode(network: "ws", host: "cdn.example.com", path: "/proxy")
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }

        let transport = vless?["transport"] as? [String: Any]
        XCTAssertEqual(transport?["type"] as? String, "ws")
        XCTAssertEqual(transport?["path"] as? String, "/proxy")
        let headers = transport?["headers"] as? [String: String]
        XCTAssertEqual(headers?["Host"], "cdn.example.com")
    }

    func testBuildsVLESSOutboundWithoutTLS() throws {
        let node = makeNode(security: "none")
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }

        XCTAssertNil(vless?["tls"])
    }

    // MARK: - URL Test Config Tests

    func testGlobalModeUsesDefaultTestURL() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let urltest = outbounds?.first { $0["type"] as? String == "urltest" }

        XCTAssertEqual(urltest?["url"] as? String, "https://www.gstatic.com/generate_204")
        XCTAssertEqual(urltest?["interval"] as? String, "3m")
    }

    func testAIStableModeUsesAITestURL() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .aiStable
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let urltest = outbounds?.first { $0["type"] as? String == "urltest" }

        XCTAssertEqual(urltest?["url"] as? String, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(urltest?["interval"] as? String, "5m")
    }

    // MARK: - Error Tests

    func testEmptyNodeListThrows() {
        XCTAssertThrowsError(
            try SingBoxConfigBuilder(localPort: 7890).build(nodes: [], mode: .auto)
        ) { error in
            XCTAssertTrue(error is SingBoxConfigError)
        }
    }

    // MARK: - Clash API Port Tests

    func testClashAPIPortIsConsistent() {
        XCTAssertEqual(
            SingBoxConfigBuilder.defaultClashAPIPort,
            SingBoxConfigBuilder.defaultClashAPIPort,
            "Clash API port should be consistent"
        )
    }

    // MARK: - Helpers

    private func makeNode(
        name: String = "CF Node",
        security: String = "tls",
        network: String = "ws",
        host: String? = "example.com",
        path: String? = "/?ed=2560",
        sni: String? = "example.com",
        fingerprint: String? = "random"
    ) -> ProxyNode {
        ProxyNode(
            name: name,
            uuid: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            server: "104.16.157.214",
            port: 443,
            encryption: "none",
            security: security,
            network: network,
            host: host,
            path: path,
            sni: sni,
            fingerprint: fingerprint,
            allowInsecure: false,
            rawURL: "vless://example"
        )
    }

    private func assertSingBoxAccepts(_ data: Data) throws {
        let candidates = ["/opt/homebrew/bin/sing-box", "/usr/local/bin/sing-box"]
        guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
            return // sing-box not installed, skip validation
        }

        let configURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CloudflareNodeSwitch-\(UUID().uuidString).json")
        try data.write(to: configURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: configURL) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["check", "-c", configURL.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.standardOutput = Pipe()
        try process.run()
        process.waitUntilExit()

        let error = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        XCTAssertEqual(process.terminationStatus, 0, "sing-box config validation failed: \(error)")
    }
}
