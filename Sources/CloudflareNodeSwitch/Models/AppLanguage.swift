import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english
    case chineseSimplified

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .english:
            return "English"
        case .chineseSimplified:
            return "简体中文"
        }
    }
}
