import Foundation

enum ProxyMode: Codable, Equatable {
    case auto
    case manual(UUID)

    var label: String {
        switch self {
        case .auto:
            return "Auto"
        case .manual:
            return "Manual"
        }
    }
}
