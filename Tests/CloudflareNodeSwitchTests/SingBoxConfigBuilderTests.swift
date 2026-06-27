import Foundation
import XCTest
@testable import CloudflareNodeSwitch

final class SingBoxConfigBuilderTests: XCTestCase {
    func testBuildsAutoUrltestConfig() throws {
        let node = ProxyNode(
            name: "CF Node",
            uuid: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            server: "104.16.157.214",
            port: 443,
            encryption: "none",
            security: "tls",
            network: "ws",
            host: "example.com",
            path: "/?ed=2560",
            sni: "example.com",
            fingerprint: "random",
            allowInsecure: true,
            rawURL: "vless://example"
        )

        let data = try SingBoxConfigBuilder(localPort: 7890).build(nodes: [node], mode: .auto, routingMode: .aiStable)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual((object?["log"] as? [String: Any])?["level"] as? String, "warn")
        let experimental = object?["experimental"] as? [String: Any]
        let clashAPI = experimental?["clash_api"] as? [String: Any]
        XCTAssertEqual(clashAPI?["external_controller"] as? String, "127.0.0.1:19090")
        XCTAssertEqual((object?["route"] as? [String: Any])?["final"] as? String, "auto")

        let inbounds = object?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.first?["listen_port"] as? Int, 7890)
        XCTAssertNil(inbounds?.first?["sniff"])
        XCTAssertNil(inbounds?.first?["sniff_override_destination"])

        let route = object?["route"] as? [String: Any]
        let rules = route?["rules"] as? [[String: Any]]
        XCTAssertEqual(rules?.first?["inbound"] as? String, "mixed-in")
        XCTAssertEqual(rules?.first?["action"] as? String, "sniff")
        XCTAssertNil(rules?.first?["sniff_override_destination"])
        XCTAssertEqual(rules?[1]["ip_is_private"] as? Bool, true)
        XCTAssertEqual(rules?[1]["action"] as? String, "route")
        XCTAssertEqual(rules?[1]["outbound"] as? String, "direct")
        XCTAssertEqual(rules?[2]["outbound"] as? String, "auto")
        XCTAssertEqual(rules?[3]["outbound"] as? String, "direct")

        let outbounds = object?["outbounds"] as? [[String: Any]]
        XCTAssertEqual(outbounds?.first?["type"] as? String, "urltest")
        XCTAssertEqual(outbounds?.first?["tag"] as? String, "auto")
        XCTAssertEqual(outbounds?.first?["url"] as? String, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(outbounds?.first?["interval"] as? String, "5m")
        XCTAssertEqual(outbounds?.first?["tolerance"] as? Int, SingBoxConfigBuilder.autoSelectionTolerance)
        XCTAssertEqual(outbounds?.first?["idle_timeout"] as? String, "30m")
        XCTAssertEqual(outbounds?.first?["interrupt_exist_connections"] as? Bool, false)

        let vless = outbounds?.first { $0["type"] as? String == "vless" }
        XCTAssertEqual(vless?["server"] as? String, "104.16.157.214")
        XCTAssertEqual(vless?["server_port"] as? Int, 443)
        XCTAssertEqual((vless?["tls"] as? [String: Any])?["server_name"] as? String, "example.com")
        XCTAssertEqual((vless?["transport"] as? [String: Any])?["type"] as? String, "ws")

        try assertSingBoxAccepts(data)
    }

    func testBuildsModernTunConfig() throws {
        let node = makeNode()
        let data = try SingBoxConfigBuilder(localPort: 7890).build(
            nodes: [node],
            mode: .auto,
            routingMode: .smartCN,
            inboundMode: .tun
        )
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let inbounds = object?["inbounds"] as? [[String: Any]]
        XCTAssertEqual(inbounds?.first?["type"] as? String, "tun")
        XCTAssertEqual(inbounds?.first?["address"] as? [String], ["172.19.0.1/30"])
        XCTAssertNil(inbounds?.first?["inet4_address"])
        XCTAssertNil(inbounds?.first?["sniff"])

        try assertSingBoxAccepts(data)
    }

    private func makeNode() -> ProxyNode {
        ProxyNode(
            name: "CF Node",
            uuid: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            server: "104.16.157.214",
            port: 443,
            encryption: "none",
            security: "tls",
            network: "ws",
            host: "example.com",
            path: "/?ed=2560",
            sni: "example.com",
            fingerprint: "random",
            allowInsecure: true,
            rawURL: "vless://example"
        )
    }

    private func assertSingBoxAccepts(_ data: Data) throws {
        let candidates = ["/opt/homebrew/bin/sing-box", "/usr/local/bin/sing-box"]
        guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
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
        XCTAssertEqual(process.terminationStatus, 0, error)
    }
}
