import XCTest
@testable import CloudflareNodeSwitch

final class LocalizedStringTests: XCTestCase {

    // MARK: - Non-empty Validation

    func testAllCommonStringsAreNonEmpty() {
        let strings: [(String, String)] = [
            (LocalizedString.appTitle, "appTitle"),
            (LocalizedString.running, "running"),
            (LocalizedString.stopped, "stopped"),
            (LocalizedString.autoSelect, "autoSelect"),
            (LocalizedString.nodes, "nodes"),
            (LocalizedString.useThisNode, "useThisNode"),
            (LocalizedString.active, "active"),
            (LocalizedString.refresh, "refresh"),
            (LocalizedString.start, "start"),
            (LocalizedString.stop, "stop"),
            (LocalizedString.test, "test"),
            (LocalizedString.settings, "settings"),
            (LocalizedString.subscription, "subscription"),
            (LocalizedString.localPort, "localPort"),
            (LocalizedString.routing, "routing"),
            (LocalizedString.integration, "integration"),
            (LocalizedString.inbound, "inbound"),
            (LocalizedString.node, "node"),
            (LocalizedString.name, "name"),
            (LocalizedString.endpoint, "endpoint"),
            (LocalizedString.network, "network"),
            (LocalizedString.country, "country"),
            (LocalizedString.log, "log"),
            (LocalizedString.quit, "quit"),
        ]

        for (value, name) in strings {
            XCTAssertFalse(value.isEmpty, "\(name) should not be empty")
        }
    }

    func testStatusMessagesAreNonEmpty() {
        let strings: [(String, String)] = [
            (LocalizedString.pasteSubscriptionHint, "pasteSubscriptionHint"),
            (LocalizedString.subscriptionEmpty, "subscriptionEmpty"),
            (LocalizedString.refreshingSubscription, "refreshingSubscription"),
            (LocalizedString.noNodesToTest, "noNodesToTest"),
            (LocalizedString.testingTCPLatency, "testingTCPLatency"),
            (LocalizedString.proxyStarted, "proxyStarted"),
            (LocalizedString.proxyStopped, "proxyStopped"),
            (LocalizedString.noNodesLoaded, "noNodesLoaded"),
        ]

        for (value, name) in strings {
            XCTAssertFalse(value.isEmpty, "\(name) should not be empty")
        }
    }

    func testErrorMessagesAreNonEmpty() {
        let strings: [(String, String)] = [
            (LocalizedString.singBoxNotFound, "singBoxNotFound"),
            (LocalizedString.noNodesAvailable, "noNodesAvailable"),
            (LocalizedString.selectedNodeMissing, "selectedNodeMissing"),
            (LocalizedString.noSupportedNodes, "noSupportedNodes"),
            (LocalizedString.failedOpenTerminal, "failedOpenTerminal"),
            (LocalizedString.launchctlFailed, "launchctlFailed"),
        ]

        for (value, name) in strings {
            XCTAssertFalse(value.isEmpty, "\(name) should not be empty")
        }
    }

    // MARK: - Format Strings

    func testLoadedNodesFormatStringContainsArgument() {
        let result = String(format: LocalizedString.loadedNodes, 42)
        XCTAssertTrue(result.contains("42"), "Format string should contain the number")
    }

    func testRefreshFailedFormatStringContainsArgument() {
        let result = String(format: LocalizedString.refreshFailed, "timeout")
        XCTAssertTrue(result.contains("timeout"), "Format string should contain the error")
    }

    func testSelectedNodeFormatStringContainsArgument() {
        let result = String(format: LocalizedString.selectedNode, "MyNode")
        XCTAssertTrue(result.contains("MyNode"), "Format string should contain the node name")
    }

    func testNodeFallbackFormatStringContainsArgument() {
        let result = String(format: LocalizedString.nodeFallback, 5)
        XCTAssertTrue(result.contains("5"), "Format string should contain the number")
    }

    func testSingBoxExitedFormatStringContainsArgument() {
        let result = String(format: LocalizedString.singBoxExited, 137)
        XCTAssertTrue(result.contains("137"), "Format string should contain exit code")
    }

    func testCommandNotFoundFormatStringContainsArgument() {
        let result = String(format: LocalizedString.commandNotFoundProxyActive, "codex")
        XCTAssertTrue(result.contains("codex"), "Format string should contain command name")
    }

    // MARK: - Distinctness

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

    func testStatusStringsAreDistinct() {
        XCTAssertNotEqual(LocalizedString.running, LocalizedString.stopped)
        XCTAssertNotEqual(LocalizedString.proxyStarted, LocalizedString.proxyStopped)
        XCTAssertNotEqual(LocalizedString.proxyStarted, LocalizedString.proxyRestarted)
        XCTAssertNotEqual(LocalizedString.systemProxyEnabled, LocalizedString.systemProxyDisabled)
    }

    // MARK: - Localization Correctness

    func testCountryFilterStringHasKnownValue() {
        let value = LocalizedString.allCountries
        // 根据系统语言应为中文或英文
        XCTAssertTrue(
            value == "全部" || value == "All",
            "Expected '全部' (zh) or 'All' (en), got: \(value)"
        )
    }

    func testNodeCountStringDiffersFromNodes() {
        // nodeCount 用于指标卡片（节点数），nodes 用于列表标题（节点）
        // 英文场景下 nodeCount 应为 "Node Count" 而非 "Nodes"
        let count = LocalizedString.nodeCount
        let list = LocalizedString.nodes
        // 至少有一个不同（中文可能相同）
        XCTAssertTrue(count != list || LocalizedString.isChinese,
                      "nodeCount and nodes should differ in non-Chinese locales")
    }

    // MARK: - isChinese

    func testIsChineseReturnsConsistentValue() {
        // isChinese 在进程生命周期内应保持不变
        let first = LocalizedString.isChinese
        let second = LocalizedString.isChinese
        XCTAssertEqual(first, second, "isChinese should be stable across calls")
    }
}
