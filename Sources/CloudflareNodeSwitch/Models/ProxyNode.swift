import Foundation

struct ProxyNode: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var uuid: String
    var server: String
    var port: Int
    var encryption: String
    var security: String
    var network: String
    var host: String?
    var path: String?
    var sni: String?
    var fingerprint: String?
    var allowInsecure: Bool
    var rawURL: String
    var countryCode: String?

    init(
        id: UUID = UUID(),
        name: String,
        uuid: String,
        server: String,
        port: Int,
        encryption: String,
        security: String,
        network: String,
        host: String?,
        path: String?,
        sni: String?,
        fingerprint: String?,
        allowInsecure: Bool,
        rawURL: String,
        countryCode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.uuid = uuid
        self.server = server
        self.port = port
        self.encryption = encryption
        self.security = security
        self.network = network
        self.host = host
        self.path = path
        self.sni = sni
        self.fingerprint = fingerprint
        self.allowInsecure = allowInsecure
        self.rawURL = rawURL
        self.countryCode = countryCode
    }

    var endpoint: String {
        "\(server):\(port)"
    }

    var displayName: String {
        name.isEmpty ? endpoint : name
    }

    /// 国家代码（如 US、JP、HK）
    var country: String? {
        countryCode ?? CountryUtils.extractCountry(from: name)
    }

    /// 国家旗帜 emoji
    var countryFlag: String {
        guard let code = country else { return "" }
        return CountryUtils.flag(for: code)
    }

    /// 国家显示名称
    var countryName: String {
        guard let code = country else { return "" }
        return CountryUtils.name(for: code)
    }
}
