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

        let inbounds = json?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.count, 1)
        XCTAssertEqual(inbounds?.first?["type"] as? String, "mixed")
        XCTAssertEqual(inbounds?.first?["tag"] as? String, "mixed-in")
        XCTAssertEqual(inbounds?.first?["listen"] as? String, "127.0.0.1")
        XCTAssertEqual(inbounds?.first?["listen_port"] as? Int, 7890)

        // mixed 模式不应包含 dns 字段
        let dnsKeys = json?.keys.filter { $0 == "dns" }
        XCTAssertTrue(dnsKeys?.isEmpty ?? true, "Mixed mode should not have dns key")

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

        // TUN inbound
        let inbounds = json?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.count, 1)
        XCTAssertEqual(inbounds?.first?["type"] as? String, "tun")
        XCTAssertEqual(inbounds?.first?["tag"] as? String, "tun-in")
        XCTAssertEqual(inbounds?.first?["interface_name"] as? String, "utun10")
        XCTAssertEqual(inbounds?.first?["address"] as? [String], ["172.19.0.1/30"])
        XCTAssertEqual(inbounds?.first?["auto_route"] as? Bool, true)
        XCTAssertEqual(inbounds?.first?["strict_route"] as? Bool, false)
        XCTAssertEqual(inbounds?.first?["stack"] as? String, "system")

        // DNS 配置 — 完整验证
        let dns = json?["dns"] as? [String: Any]
        XCTAssertNotNil(dns, "TUN mode must have DNS config")
        let servers = dns?["servers"] as? [[String: Any]]
        XCTAssertEqual(servers?.count, 2)

        // 第一个 DNS 服务器
        XCTAssertEqual(servers?.first?["type"] as? String, "https")
        XCTAssertEqual(servers?.first?["tag"] as? String, "dns-direct")
        XCTAssertEqual(servers?.first?["server"] as? String, "8.8.8.8")
        XCTAssertEqual(servers?.first?["path"] as? String, "/dns-query")
        XCTAssertNil(servers?.first?["detour"])
        let directTLS = servers?.first?["tls"] as? [String: Any]
        XCTAssertEqual(directTLS?["server_name"] as? String, "dns.google")

        // 第二个 DNS 服务器
        XCTAssertEqual(servers?[1]["type"] as? String, "https")
        XCTAssertEqual(servers?[1]["tag"] as? String, "dns-proxy")
        XCTAssertEqual(servers?[1]["server"] as? String, "1.1.1.1")
        XCTAssertEqual(servers?[1]["path"] as? String, "/dns-query")
        XCTAssertEqual(servers?[1]["detour"] as? String, "auto")
        let proxyTLS = servers?[1]["tls"] as? [String: Any]
        XCTAssertEqual(proxyTLS?["server_name"] as? String, "cloudflare-dns.com")

        // 路由规则使用 tun-in
        let route = json?["route"] as? [String: Any]
        let rules = route?["rules"] as? [[String: Any]]
        XCTAssertEqual(rules?.first?["inbound"] as? String, "tun-in")
        XCTAssertEqual(rules?.first?["action"] as? String, "sniff")

        try assertSingBoxAccepts(data)
        try assertSingBoxInitializesServices(data)
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

        // Global: sniff + local direct
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
        ) { error in
            guard let configError = error as? SingBoxConfigError else {
                XCTFail("Expected SingBoxConfigError, got \(type(of: error))")
                return
            }
            if case .selectedNodeMissing = configError {
                // correct
            } else {
                XCTFail("Expected .selectedNodeMissing, got \(configError)")
            }
        }
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
        XCTAssertEqual(vless?["uuid"] as? String, "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")

        let tls = vless?["tls"] as? [String: Any]
        XCTAssertEqual(tls?["enabled"] as? Bool, true)
        XCTAssertEqual(tls?["server_name"] as? String, "example.com")
        XCTAssertEqual(tls?["insecure"] as? Bool, false)

        let utls = tls?["utls"] as? [String: Any]
        XCTAssertEqual(utls?["enabled"] as? Bool, true)
        XCTAssertEqual(utls?["fingerprint"] as? String, "chrome")
    }

    func testBuildsVLESSOutboundWithTLSAndInsecure() throws {
        let node = makeNode(security: "tls", sni: "test.com", allowInsecure: true)
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }
        let tls = vless?["tls"] as? [String: Any]

        XCTAssertEqual(tls?["insecure"] as? Bool, true)
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

    func testBuildsVLESSOutboundWithWebSocketDefaultPath() throws {
        let node = makeNode(network: "ws", host: "cdn.example.com", path: nil)
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }

        let transport = vless?["transport"] as? [String: Any]
        XCTAssertEqual(transport?["path"] as? String, "/")
    }

    func testBuildsVLESSOutboundWithoutWS() throws {
        // network = "tcp" — 不应生成 transport
        let node = makeNode(network: "tcp", host: nil, path: nil)
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vless = outbounds?.first { $0["type"] as? String == "vless" }

        XCTAssertNil(vless?["transport"])
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

    func testSmartCNModeUsesDefaultTestURL() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .smartCN
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

    // MARK: - Multiple Nodes Tests

    func testBuildsConfigWithMultipleNodes() throws {
        let nodes = (0..<5).map { makeNode(name: "Node \($0 + 1)") }
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: nodes,
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let outbounds = json?["outbounds"] as? [[String: Any]]
        let vlessOutbounds = outbounds?.filter { $0["type"] as? String == "vless" }

        XCTAssertEqual(vlessOutbounds?.count, 5)

        // urltest outbound 应包含所有 node tags
        let urltest = outbounds?.first { $0["type"] as? String == "urltest" }
        let urltestOutbounds = urltest?["outbounds"] as? [String]
        XCTAssertEqual(urltestOutbounds, ["node-1", "node-2", "node-3", "node-4", "node-5"])
    }

    // MARK: - Error Tests

    func testEmptyNodeListThrowsEmptyNodeListError() {
        XCTAssertThrowsError(
            try SingBoxConfigBuilder(localPort: 7890).build(nodes: [], mode: .auto)
        ) { error in
            guard let configError = error as? SingBoxConfigError else {
                XCTFail("Expected SingBoxConfigError, got \(type(of: error))")
                return
            }
            if case .emptyNodeList = configError {
                // correct
            } else {
                XCTFail("Expected .emptyNodeList, got \(configError)")
            }
        }
    }

    // MARK: - Clash API Port Tests

    func testClashAPIPortValue() {
        XCTAssertEqual(SingBoxConfigBuilder.defaultClashAPIPort, 19090)
    }

    func testClashAPIPortAppearsInConfig() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .global
        )
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let experimental = json?["experimental"] as? [String: Any]
        let clashAPI = experimental?["clash_api"] as? [String: Any]
        XCTAssertEqual(clashAPI?["external_controller"] as? String, "127.0.0.1:19090")
    }

    // MARK: - Helpers

    private func makeNode(
        name: String = "CF Node",
        security: String = "tls",
        network: String = "ws",
        host: String? = "example.com",
        path: String? = "/?ed=2560",
        sni: String? = "example.com",
        fingerprint: String? = "random",
        allowInsecure: Bool = false
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
            allowInsecure: allowInsecure,
            rawURL: "vless://example"
        )
    }

    private func assertSingBoxAccepts(_ data: Data) throws {
        guard let executable = singBoxExecutable() else {
            print("⚠️ sing-box not installed, skipping config validation")
            return
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

    private func assertSingBoxInitializesServices(_ data: Data) throws {
        guard let executable = singBoxExecutable() else {
            return
        }

        var config = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        config.removeValue(forKey: "experimental")
        config["inbounds"] = [[
            "type": "mixed",
            "tag": "tun-in",
            "listen": "127.0.0.1",
            "listen_port": Int.random(in: 20_000...50_000)
        ]]

        let runtimeData = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        let configURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CloudflareNodeSwitch-runtime-\(UUID().uuidString).json")
        try runtimeData.write(to: configURL, options: .atomic)
        defer { try? FileManager.default.removeItem(at: configURL) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = ["run", "-c", configURL.path]
        let outputPipe = Pipe()
        process.standardError = outputPipe
        process.standardOutput = outputPipe
        try process.run()

        Thread.sleep(forTimeInterval: 1)
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
            return
        }

        let output = String(decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        XCTFail("sing-box service initialization failed: \(output)")
    }

    private func singBoxExecutable() -> String? {
        let candidates = [
            "dist/Cloudflare Node Switch.app/Contents/Resources/sing-box",
            "/opt/homebrew/bin/sing-box",
            "/usr/local/bin/sing-box"
        ]
        return candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) })
    }
}
