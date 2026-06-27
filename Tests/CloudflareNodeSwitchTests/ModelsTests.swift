import XCTest
@testable import CloudflareNodeSwitch

// MARK: - RoutingMode Tests

final class RoutingModeTests: XCTestCase {

    func testAllCasesExist() {
        XCTAssertEqual(RoutingMode.allCases.count, 3)
        XCTAssertTrue(RoutingMode.allCases.contains(.global))
        XCTAssertTrue(RoutingMode.allCases.contains(.smartCN))
        XCTAssertTrue(RoutingMode.allCases.contains(.aiStable))
    }

    func testIdMatchesRawValue() {
        XCTAssertEqual(RoutingMode.global.id, "global")
        XCTAssertEqual(RoutingMode.smartCN.id, "smartCN")
        XCTAssertEqual(RoutingMode.aiStable.id, "aiStable")
    }

    func testTitleIsNonEmpty() {
        for mode in RoutingMode.allCases {
            XCTAssertFalse(mode.title.isEmpty, "\(mode.rawValue) title should not be empty")
        }
    }

    func testDetailIsNonEmpty() {
        for mode in RoutingMode.allCases {
            XCTAssertFalse(mode.detail.isEmpty, "\(mode.rawValue) detail should not be empty")
        }
    }

    func testTitlesAreDistinct() {
        let titles = RoutingMode.allCases.map(\.title)
        XCTAssertEqual(Set(titles).count, titles.count, "All routing mode titles should be unique")
    }

    func testCodableRoundTrip() throws {
        for mode in RoutingMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(RoutingMode.self, from: data)
            XCTAssertEqual(mode, decoded)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(RoutingMode(rawValue: "global"), .global)
        XCTAssertEqual(RoutingMode(rawValue: "smartCN"), .smartCN)
        XCTAssertEqual(RoutingMode(rawValue: "aiStable"), .aiStable)
        XCTAssertNil(RoutingMode(rawValue: "invalid"))
    }
}

// MARK: - ProxyMode Tests

final class ProxyModeTests: XCTestCase {

    func testAutoLabel() {
        let mode = ProxyMode.auto
        XCTAssertFalse(mode.label.isEmpty)
    }

    func testManualLabel() {
        let mode = ProxyMode.manual(UUID())
        XCTAssertFalse(mode.label.isEmpty)
    }

    func testAutoEqualsAuto() {
        XCTAssertEqual(ProxyMode.auto, ProxyMode.auto)
    }

    func testManualWithSameIdAreEqual() {
        let id = UUID()
        XCTAssertEqual(ProxyMode.manual(id), ProxyMode.manual(id))
    }

    func testManualWithDifferentIdAreNotEqual() {
        XCTAssertNotEqual(ProxyMode.manual(UUID()), ProxyMode.manual(UUID()))
    }

    func testAutoNotEqualToManual() {
        XCTAssertNotEqual(ProxyMode.auto, ProxyMode.manual(UUID()))
    }

    func testCodableRoundTripAuto() throws {
        let mode = ProxyMode.auto
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(ProxyMode.self, from: data)
        XCTAssertEqual(mode, decoded)
    }

    func testCodableRoundTripManual() throws {
        let id = UUID()
        let mode = ProxyMode.manual(id)
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(ProxyMode.self, from: data)
        XCTAssertEqual(mode, decoded)
    }
}

// MARK: - NodeLatency Tests

final class NodeLatencyTests: XCTestCase {

    func testSortValueOrdering() {
        // alive < testing < unknown < failed
        let alive = NodeLatency.alive(milliseconds: 100)
        let testing = NodeLatency.testing
        let unknown = NodeLatency.unknown
        let failed = NodeLatency.failed

        XCTAssertLessThan(alive.sortValue, testing.sortValue)
        XCTAssertLessThan(testing.sortValue, unknown.sortValue)
        XCTAssertLessThan(unknown.sortValue, failed.sortValue)
    }

    func testAliveSortValueIsLatency() {
        XCTAssertEqual(NodeLatency.alive(milliseconds: 50).sortValue, 50)
        XCTAssertEqual(NodeLatency.alive(milliseconds: 999).sortValue, 999)
    }

    func testLabelForAlive() {
        XCTAssertEqual(NodeLatency.alive(milliseconds: 100).label, "100 ms")
        XCTAssertEqual(NodeLatency.alive(milliseconds: 0).label, "0 ms")
    }

    func testLabelForUnknown() {
        XCTAssertEqual(NodeLatency.unknown.label, "-")
    }

    func testLabelForFailed() {
        XCTAssertEqual(NodeLatency.failed.label, "×")
    }

    func testCodableRoundTrip() throws {
        let cases: [NodeLatency] = [
            .unknown, .testing, .alive(milliseconds: 150), .failed
        ]
        for latency in cases {
            let data = try JSONEncoder().encode(latency)
            let decoded = try JSONDecoder().decode(NodeLatency.self, from: data)
            XCTAssertEqual(latency, decoded)
        }
    }

    func testHashable() {
        var set = Set<NodeLatency>()
        set.insert(.unknown)
        set.insert(.testing)
        set.insert(.alive(milliseconds: 100))
        set.insert(.alive(milliseconds: 200))
        set.insert(.failed)
        XCTAssertEqual(set.count, 5)
    }
}

// MARK: - InboundMode Tests

final class InboundModeTests: XCTestCase {

    func testAllCasesExist() {
        XCTAssertEqual(InboundMode.allCases.count, 2)
        XCTAssertTrue(InboundMode.allCases.contains(.mixed))
        XCTAssertTrue(InboundMode.allCases.contains(.tun))
    }

    func testIdMatchesRawValue() {
        XCTAssertEqual(InboundMode.mixed.id, "mixed")
        XCTAssertEqual(InboundMode.tun.id, "tun")
    }

    func testTitleIsNonEmpty() {
        for mode in InboundMode.allCases {
            XCTAssertFalse(mode.title.isEmpty, "\(mode.rawValue) title should not be empty")
        }
    }

    func testDetailIsNonEmpty() {
        for mode in InboundMode.allCases {
            XCTAssertFalse(mode.detail.isEmpty, "\(mode.rawValue) detail should not be empty")
        }
    }

    func testTitlesAreDistinct() {
        XCTAssertNotEqual(InboundMode.mixed.title, InboundMode.tun.title)
    }

    func testCodableRoundTrip() throws {
        for mode in InboundMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(InboundMode.self, from: data)
            XCTAssertEqual(mode, decoded)
        }
    }
}
