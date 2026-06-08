import Foundation
import Network

struct LatencyTester {
    func measure(node: ProxyNode, timeout: TimeInterval = 4) async -> NodeLatency {
        guard let port = NWEndpoint.Port(rawValue: UInt16(node.port)) else {
            return .failed
        }

        let milliseconds: Int? = await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
            let queue = DispatchQueue(label: "LatencyTester.\(node.id.uuidString)")
            let startedAt = Date()
            let connection = NWConnection(host: NWEndpoint.Host(node.server), port: port, using: .tcp)
            let box = LatencyContinuationBox(connection: connection, continuation: continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    box.finish(Int(Date().timeIntervalSince(startedAt) * 1000))
                case .failed, .waiting:
                    box.finish(nil)
                default:
                    break
                }
            }

            connection.start(queue: queue)
            queue.asyncAfter(deadline: .now() + timeout) {
                box.finish(nil)
            }
        }

        if let milliseconds {
            return .alive(milliseconds: milliseconds)
        }
        return .failed
    }
}

private final class LatencyContinuationBox: @unchecked Sendable {
    private let lock = NSLock()
    private let connection: NWConnection
    private let continuation: CheckedContinuation<Int?, Never>
    private var didResume = false

    init(connection: NWConnection, continuation: CheckedContinuation<Int?, Never>) {
        self.connection = connection
        self.continuation = continuation
    }

    func finish(_ result: Int?) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        lock.unlock()

        connection.cancel()
        continuation.resume(returning: result)
    }
}
