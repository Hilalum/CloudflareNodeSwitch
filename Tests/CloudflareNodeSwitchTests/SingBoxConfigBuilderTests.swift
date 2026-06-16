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
        XCTAssertEqual(outbounds?.first?["tolerance"] as? Int, 150)
        XCTAssertEqual(outbounds?.first?["idle_timeout"] as? String, "30m")
        XCTAssertEqual(outbounds?.first?["interrupt_exist_connections"] as? Bool, false)

        let vless = outbounds?.first { $0["type"] as? String == "vless" }
        XCTAssertEqual(vless?["server"] as? String, "104.16.157.214")
        XCTAssertEqual(vless?["server_port"] as? Int, 443)
        XCTAssertEqual((vless?["tls"] as? [String: Any])?["server_name"] as? String, "example.com")
        XCTAssertEqual((vless?["transport"] as? [String: Any])?["type"] as? String, "ws")
    }
}
