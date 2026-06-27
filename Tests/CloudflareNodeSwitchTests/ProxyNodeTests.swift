import XCTest
@testable import CloudflareNodeSwitch

final class ProxyNodeTests: XCTestCase {

    // MARK: - Basic Properties

    func testNodeInitialization() {
        let node = makeNode()

        XCTAssertEqual(node.name, "Test Node")
        XCTAssertEqual(node.uuid, "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")
        XCTAssertEqual(node.server, "104.16.157.214")
        XCTAssertEqual(node.port, 443)
        XCTAssertEqual(node.encryption, "none")
        XCTAssertEqual(node.security, "tls")
        XCTAssertEqual(node.network, "ws")
        XCTAssertEqual(node.host, "example.com")
        XCTAssertEqual(node.path, "/proxy")
        XCTAssertEqual(node.sni, "example.com")
        XCTAssertEqual(node.fingerprint, "chrome")
        XCTAssertFalse(node.allowInsecure)
        XCTAssertEqual(node.rawURL, "vless://example")
    }

    func testNodeHasUniqueID() {
        let node1 = makeNode()
        let node2 = makeNode()

        XCTAssertNotEqual(node1.id, node2.id)
    }

    // MARK: - Endpoint

    func testEndpointFormat() {
        let node = makeNode(server: "10.0.0.1", port: 8443)
        XCTAssertEqual(node.endpoint, "10.0.0.1:8443")
    }

    func testEndpointWithIPV6() {
        let node = makeNode(server: "2001:db8::1", port: 443)
        XCTAssertEqual(node.endpoint, "2001:db8::1:443")
    }

    // MARK: - Display Name

    func testDisplayNameReturnsNameWhenNotEmpty() {
        let node = makeNode(name: "My Node")
        XCTAssertEqual(node.displayName, "My Node")
    }

    func testDisplayNameReturnsEndpointWhenNameEmpty() {
        let node = makeNode(name: "", server: "10.0.0.1", port: 443)
        XCTAssertEqual(node.displayName, "10.0.0.1:443")
    }

    // MARK: - Country Properties

    func testCountryFromFlagEmojiName() {
        let node = makeNode(name: "🇺🇸US Node")
        XCTAssertEqual(node.country, "US")
        XCTAssertEqual(node.countryFlag, "🇺🇸")
        XCTAssertFalse(node.countryName.isEmpty)
    }

    func testCountryFromBracketsName() {
        let node = makeNode(name: "[JP] Japan Node")
        XCTAssertEqual(node.country, "JP")
        XCTAssertEqual(node.countryFlag, "🇯🇵")
    }

    func testCountryFromPrefixName() {
        let node = makeNode(name: "SG - Singapore")
        XCTAssertEqual(node.country, "SG")
        XCTAssertEqual(node.countryFlag, "🇸🇬")
    }

    func testCountryFromSuffixName() {
        let node = makeNode(name: "Node - HK")
        XCTAssertEqual(node.country, "HK")
        XCTAssertEqual(node.countryFlag, "🇭🇰")
    }

    func testCountryIsNilWhenNotDetected() {
        let node = makeNode(name: "Random Node Name")
        XCTAssertNil(node.country)
        XCTAssertEqual(node.countryFlag, "")
        XCTAssertEqual(node.countryName, "")
    }

    func testCountryNameMatchesCode() {
        let node = makeNode(name: "US Node")
        let name = node.countryName
        // Should be either Chinese or English name
        XCTAssertTrue(name == "美国" || name == "United States",
                      "Expected localized name for US, got: \(name)")
    }

    // MARK: - Codable

    func testNodeCodable() throws {
        let original = makeNode()
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProxyNode.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.server, decoded.server)
        XCTAssertEqual(original.port, decoded.port)
    }

    // MARK: - Hashable

    func testNodeHashable() {
        let node1 = makeNode()
        let node2 = makeNode()

        var set = Set<ProxyNode>()
        set.insert(node1)
        set.insert(node2)

        // Different nodes should have different IDs
        XCTAssertEqual(set.count, 2)
    }

    func testNodeEquality() {
        let node1 = makeNode(name: "Same Name")
        let node2 = makeNode(name: "Same Name")

        // Different instances with same data should not be equal (different IDs)
        XCTAssertNotEqual(node1, node2)
    }

    // MARK: - Optional Properties

    func testNodeWithMinimalProperties() {
        let node = ProxyNode(
            name: "Minimal",
            uuid: "uuid",
            server: "server.com",
            port: 443,
            encryption: "none",
            security: "none",
            network: "tcp",
            host: nil,
            path: nil,
            sni: nil,
            fingerprint: nil,
            allowInsecure: false,
            rawURL: "vless://minimal"
        )

        XCTAssertNil(node.host)
        XCTAssertNil(node.path)
        XCTAssertNil(node.sni)
        XCTAssertNil(node.fingerprint)
        XCTAssertNil(node.country) // No country in name
    }

    // MARK: - Helpers

    private func makeNode(
        name: String = "Test Node",
        server: String = "104.16.157.214",
        port: Int = 443
    ) -> ProxyNode {
        ProxyNode(
            name: name,
            uuid: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
            server: server,
            port: port,
            encryption: "none",
            security: "tls",
            network: "ws",
            host: "example.com",
            path: "/proxy",
            sni: "example.com",
            fingerprint: "chrome",
            allowInsecure: false,
            rawURL: "vless://example"
        )
    }
}
