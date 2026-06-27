import Foundation

enum ProxyMode: Codable, Equatable {
    case auto
    case manual(UUID)

    var label: String {
        switch self {
        case .auto:
            return LocalizedString.auto
        case .manual:
            return LocalizedString.manual
        }
    }
}
