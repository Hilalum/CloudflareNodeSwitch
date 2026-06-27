import Foundation

enum NodeLatency: Codable, Hashable {
    case unknown
    case testing
    case alive(milliseconds: Int)
    case failed

    var sortValue: Int {
        switch self {
        case .alive(let milliseconds):
            return milliseconds
        case .testing:
            return Int.max - 2
        case .unknown:
            return Int.max - 1
        case .failed:
            return Int.max
        }
    }

    var label: String {
        switch self {
        case .unknown:
            return "-"
        case .testing:
            return "..."
        case .alive(let milliseconds):
            return "\(milliseconds) ms"
        case .failed:
            return "×"
        }
    }
}
