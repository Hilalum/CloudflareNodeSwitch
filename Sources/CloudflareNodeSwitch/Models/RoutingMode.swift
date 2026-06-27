import Foundation

enum RoutingMode: String, CaseIterable, Identifiable, Codable {
    case global
    case smartCN
    case aiStable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .global:
            return LocalizedString.globalTitle
        case .smartCN:
            return LocalizedString.smartCNTitle
        case .aiStable:
            return LocalizedString.aiStableTitle
        }
    }

    var detail: String {
        switch self {
        case .global:
            return LocalizedString.globalDetail
        case .smartCN:
            return LocalizedString.smartCNDetail
        case .aiStable:
            return LocalizedString.aiStableDetail
        }
    }
}
