import XCTest
@testable import CloudflareNodeSwitch

final class SubscriptionParserTests: XCTestCase {
    func testParsesBase64WrappedVLESSLinks() throws {
        let link = "vless://aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee@104.16.157.214:443?encryption=none&security=tls&sni=example.com&fp=random&type=ws&host=example.com&path=%2F%3Fed%3D2560&allowInsecure=1#CF%20Node"
        let wrapped = Data(link.utf8).base64EncodedString()

        let nodes = try SubscriptionParser().parse(wrapped)

        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].name, "CF Node")
        XCTAssertEqual(nodes[0].server, "104.16.157.214")
        XCTAssertEqual(nodes[0].port, 443)
        XCTAssertEqual(nodes[0].network, "ws")
        XCTAssertEqual(nodes[0].path, "/?ed=2560")
        XCTAssertEqual(nodes[0].sni, "example.com")
        XCTAssertTrue(nodes[0].allowInsecure)
    }

    func testRejectsUnsupportedSubscription() {
        XCTAssertThrowsError(try SubscriptionParser().parse("not a subscription"))
    }
}
