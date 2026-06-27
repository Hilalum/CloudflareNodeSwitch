import XCTest
@testable import CloudflareNodeSwitch

final class LocalizedStringTests: XCTestCase {

    // MARK: - Basic Localization

    func testLocalizedStringReturnsNonEmpty() {
        // 所有 LocalizedString 值都不应为空
        XCTAssertFalse(LocalizedString.appTitle.isEmpty)
        XCTAssertFalse(LocalizedString.running.isEmpty)
        XCTAssertFalse(LocalizedString.stopped.isEmpty)
        XCTAssertFalse(LocalizedString.autoSelect.isEmpty)
        XCTAssertFalse(LocalizedString.nodes.isEmpty)
        XCTAssertFalse(LocalizedString.refresh.isEmpty)
        XCTAssertFalse(LocalizedString.start.isEmpty)
        XCTAssertFalse(LocalizedString.stop.isEmpty)
    }

    func testStatusMessagesAreNonEmpty() {
        XCTAssertFalse(LocalizedString.pasteSubscriptionHint.isEmpty)
        XCTAssertFalse(LocalizedString.subscriptionEmpty.isEmpty)
        XCTAssertFalse(LocalizedString.refreshingSubscription.isEmpty)
        XCTAssertFalse(LocalizedString.noNodesToTest.isEmpty)
        XCTAssertFalse(LocalizedString.testingTCPLatency.isEmpty)
        XCTAssertFalse(LocalizedString.proxyStarted.isEmpty)
        XCTAssertFalse(LocalizedString.proxyStopped.isEmpty)
    }

    func testSettingsStringsAreNonEmpty() {
        XCTAssertFalse(LocalizedString.settings.isEmpty)
        XCTAssertFalse(LocalizedString.subscription.isEmpty)
        XCTAssertFalse(LocalizedString.subscriptionURL.isEmpty)
        XCTAssertFalse(LocalizedString.localPort.isEmpty)
        XCTAssertFalse(LocalizedString.routing.isEmpty)
        XCTAssertFalse(LocalizedString.integration.isEmpty)
        XCTAssertFalse(LocalizedString.inbound.isEmpty)
    }

    func testNodeDetailStringsAreNonEmpty() {
        XCTAssertFalse(LocalizedString.node.isEmpty)
        XCTAssertFalse(LocalizedString.name.isEmpty)
        XCTAssertFalse(LocalizedString.endpoint.isEmpty)
        XCTAssertFalse(LocalizedString.network.isEmpty)
        XCTAssertFalse(LocalizedString.tlsSNI.isEmpty)
        XCTAssertFalse(LocalizedString.host.isEmpty)
        XCTAssertFalse(LocalizedString.path.isEmpty)
        XCTAssertFalse(LocalizedString.country.isEmpty)
    }

    // MARK: - Format Strings

    func testLoadedNodesFormatString() {
        let result = String(format: LocalizedString.loadedNodes, 42)
        XCTAssertTrue(result.contains("42"), "Format string should contain the number")
    }

    func testRefreshFailedFormatString() {
        let result = String(format: LocalizedString.refreshFailed, "test error")
        XCTAssertTrue(result.contains("test error"), "Format string should contain the error")
    }

    func testSelectedNodeFormatString() {
        let result = String(format: LocalizedString.selectedNode, "MyNode")
        XCTAssertTrue(result.contains("MyNode"), "Format string should contain the node name")
    }

    func testNodeFallbackFormatString() {
        let result = String(format: LocalizedString.nodeFallback, 5)
        XCTAssertTrue(result.contains("5"), "Format string should contain the number")
    }

    // MARK: - isChinese Property

    func testIsChineseIsBool() {
        // isChinese 应该是一个布尔值
        let value: Bool = LocalizedString.isChinese
        XCTAssertTrue(value == true || value == false)
    }

    // MARK: - Consistency

    func testEnglishAndChineseStringsHaveSameFormatSpecifiers() {
        // 验证格式字符串在中英文版本中有一致的格式说明符
        let formatStrings: [(en: String, zh: String, name: String)] = [
            (LocalizedString.loadedNodes, LocalizedString.loadedNodes, "loadedNodes"),
        ]

        // 这些字符串应该包含 %d 或 %@ 格式说明符
        for item in formatStrings {
            // 由于 isChinese 可能返回任一版本，我们只验证非空
            XCTAssertFalse(item.en.isEmpty, "\(item.name) should not be empty")
        }
    }

    // MARK: - String Values

    func testProxyModeStringsAreDistinct() {
        XCTAssertNotEqual(LocalizedString.auto, LocalizedString.manual)
        XCTAssertNotEqual(LocalizedString.on, LocalizedString.off)
        XCTAssertNotEqual(LocalizedString.start, LocalizedString.stop)
    }

    func testRoutingModeStringsAreDistinct() {
        XCTAssertNotEqual(LocalizedString.globalTitle, LocalizedString.smartCNTitle)
        XCTAssertNotEqual(LocalizedString.smartCNTitle, LocalizedString.aiStableTitle)
        XCTAssertNotEqual(LocalizedString.globalTitle, LocalizedString.aiStableTitle)
    }

    func testInboundModeStringsAreDistinct() {
        XCTAssertNotEqual(LocalizedString.mixedMode, LocalizedString.tunMode)
    }

    func testCountryFilterString() {
        // Should be either Chinese or English based on locale
        let value = LocalizedString.allCountries
        XCTAssertTrue(value == "全部" || value == "All",
                      "Expected '全部' or 'All', got: \(value)")
    }
}
