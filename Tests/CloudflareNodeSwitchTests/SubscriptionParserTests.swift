import XCTest
@testable import CloudflareNodeSwitch

final class SubscriptionParserTests: XCTestCase {

    // MARK: - Basic Parsing

    func testParsesSingleVLESSLink() throws {
        let link = "vless://aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@104.16.157.214:443?encryption=none&security=tls&sni=example.com&fp=random&type=ws&host=example.com&path=%2F%3Fed%3D2560&allowInsecure=1#CF%20Node"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "CF Node")
        XCTAssertEqual(nodes[0].server, "104.16.157.214")
        XCTAssertEqual(nodes[0].port, 443)
        XCTAssertEqual(nodes[0].network, "ws")
        XCTAssertEqual(nodes[0].path, "/?ed=2560")
        XCTAssertEqual(nodes[0].sni, "example.com")
        XCTAssertEqual(nodes[0].fingerprint, "random")
        XCTAssertTrue(nodes[0].allowInsecure)
        XCTAssertEqual(nodes[0].encryption, "none")
        XCTAssertEqual(nodes[0].security, "tls")
    }

    func testParsesBase64WrappedVLESSLinks() throws {
        let link = "vless://aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@104.16.157.214:443?encryption=none&security=tls&sni=example.com&fp=random&type=ws&host=example.com&path=%2F%3Fed%3D2560&allowInsecure=1#CF%20Node"
        let wrapped = Data(link.utf8).base64EncodedString()

        let nodes = try SubscriptionParser().parse(wrapped)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "CF Node")
        XCTAssertEqual(nodes[0].server, "104.16.157.214")
    }

    func testParsesMultipleVLESSLinks() throws {
        let links = """
        vless://aaa@10.0.0.1:443?security=tls#Node1
        vless://bbb@10.0.0.2:443?security=tls#Node2
        vless://ccc@10.0.0.3:443?security=tls#Node3
        """

        let nodes = try SubscriptionParser().parse(links)

        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0].name, "Node1")
        XCTAssertEqual(nodes[1].name, "Node2")
        XCTAssertEqual(nodes[2].name, "Node3")
    }

    // MARK: - URL Parameters

    func testParsesAllQueryParameters() throws {
        let link = "vless://uuid@server.com:8443?encryption=none&security=reality&sni=sni.com&fp=chrome&type=grpc&host=grpc.example.com&serviceName=grpc&pbk=publickey&sid=shortid#Test"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].encryption, "none")
        XCTAssertEqual(nodes[0].security, "reality")
        XCTAssertEqual(nodes[0].sni, "sni.com")
        XCTAssertEqual(nodes[0].fingerprint, "chrome")
        XCTAssertEqual(nodes[0].network, "grpc")
        XCTAssertEqual(nodes[0].host, "grpc.example.com")
    }

    func testHandlesMissingQueryParameters() throws {
        let link = "vless://uuid@server.com:443#Minimal"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].encryption, "none")
        XCTAssertEqual(nodes[0].security, "none")
        XCTAssertEqual(nodes[0].network, "tcp")
        XCTAssertNil(nodes[0].sni)
        XCTAssertNil(nodes[0].host)
        XCTAssertNil(nodes[0].path)
        XCTAssertNil(nodes[0].fingerprint)
        XCTAssertFalse(nodes[0].allowInsecure)
    }

    func testExtractsHostParameter() throws {
        let link = "vless://uuid@server.com:443?type=ws&host=cdn.example.com#WithHost"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].host, "cdn.example.com")
    }

    func testExtractsPathParameter() throws {
        let link = "vless://uuid@server.com:443?type=ws&path=%2Fproxy#WithPath"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].path, "/proxy")
    }

    func testHandlesAllowInsecureVariants() throws {
        let link1 = "vless://uuid@server.com:443?allowInsecure=1#T1"
        let link2 = "vless://uuid@server.com:443?allowInsecure=true#T2"
        let link3 = "vless://uuid@server.com:443?allowInsecure=0#T3"

        let nodes1 = try SubscriptionParser().parse(link1)
        let nodes2 = try SubscriptionParser().parse(link2)
        let nodes3 = try SubscriptionParser().parse(link3)

        XCTAssertTrue(nodes1[0].allowInsecure)
        XCTAssertTrue(nodes2[0].allowInsecure)
        XCTAssertFalse(nodes3[0].allowInsecure)
    }

    // MARK: - Name Handling

    func testUsesFragmentAsNodeName() throws {
        let link = "vless://uuid@server.com:443#My%20Custom%20Name"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].name, "My Custom Name")
    }

    func testGeneratesFallbackNameForEmptyName() throws {
        let link = "vless://uuid@server.com:443"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertFalse(nodes[0].name.isEmpty)
    }

    func testDeduplicatesNodeNames() throws {
        let links = """
        vless://aaa@10.0.0.1:443#Same
        vless://bbb@10.0.0.2:443#Same
        vless://ccc@10.0.0.3:443#Same
        """

        let nodes = try SubscriptionParser().parse(links)

        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0].name, "Same")
        XCTAssertEqual(nodes[1].name, "Same 2")
        XCTAssertEqual(nodes[2].name, "Same 3")
    }

    // MARK: - Error Cases

    func testRejectsNonVLESSContent() {
        XCTAssertThrowsError(try SubscriptionParser().parse("not a subscription")) { error in
            guard let parseError = error as? SubscriptionParserError else {
                XCTFail("Expected SubscriptionParserError, got \(type(of: error))")
                return
            }
            if case .noSupportedNodes = parseError {
                // correct
            } else {
                XCTFail("Expected .noSupportedNodes, got \(parseError)")
            }
        }
    }

    func testRejectsEmptyInput() {
        XCTAssertThrowsError(try SubscriptionParser().parse(""))
    }

    func testRejectsWhitespaceOnlyInput() {
        XCTAssertThrowsError(try SubscriptionParser().parse("   \n  \n  "))
    }

    func testIgnoresNonVLESLines() throws {
        let content = """
        this is not a vless link
        vless://uuid@server.com:443#Valid
        another invalid line
        """

        let nodes = try SubscriptionParser().parse(content)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "Valid")
    }

    // MARK: - Node Properties

    func testNodeHasValidID() throws {
        let link = "vless://uuid@server.com:443#Test"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertNotNil(nodes[0].id)
    }

    func testNodeStoresRawURL() throws {
        let link = "vless://uuid@server.com:443#Test"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].rawURL, link)
    }

    func testNodeEndpointFormat() throws {
        let link = "vless://uuid@10.0.0.1:8443#Test"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].endpoint, "10.0.0.1:8443")
    }

    func testDisplayNameReturnsNameWhenNotEmpty() throws {
        let link = "vless://uuid@server.com:443#MyNode"
        let nodes = try SubscriptionParser().parse(link)

        XCTAssertEqual(nodes[0].displayName, "MyNode")
    }

    // MARK: - Base64 Edge Cases

    func testHandlesBase64WithPadding() throws {
        let link = "vless://uuid@server.com:443#Padded"
        let base64 = Data(link.utf8).base64EncodedString()

        let nodes = try SubscriptionParser().parse(base64)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "Padded")
    }

    func testHandlesBase64WithURLSafeCharacters() throws {
        let link = "vless://uuid@server.com:443#Test"
        var base64 = Data(link.utf8).base64EncodedString()
        // Convert to URL-safe base64
        base64 = base64.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")

        let nodes = try SubscriptionParser().parse(base64)

        XCTAssertEqual(nodes.count, 1)
    }
}
