import Foundation

enum InboundMode: String, CaseIterable, Identifiable, Codable {
    case mixed
    case tun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mixed:
            return LocalizedString.mixedMode
        case .tun:
            return LocalizedString.tunMode
        }
    }

    var detail: String {
        switch self {
        case .mixed:
            return LocalizedString.mixedDetail
        case .tun:
            return LocalizedString.tunDetail
        }
    }
}
