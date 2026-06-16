import Foundation

enum RoutingMode: String, CaseIterable, Identifiable, Codable {
    case global
    case smartCN
    case aiStable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .global:
            return "Global"
        case .smartCN:
            return "Smart CN"
        case .aiStable:
            return "AI Stable"
        }
    }

    var detail: String {
        switch self {
        case .global:
            return "Only LAN/private addresses are direct"
        case .smartCN:
            return "CN/local traffic direct, others proxy"
        case .aiStable:
            return "AI/GitHub/Google proxy first, CN direct"
        }
    }
}
