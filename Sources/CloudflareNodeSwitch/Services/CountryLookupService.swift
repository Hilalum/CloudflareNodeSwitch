import Foundation

actor CountryLookupService {
    private var cache: [String: String] = [:]
    private let cacheURL = AppPaths.applicationSupportDirectory.appendingPathComponent("country-cache.json")

    init() {
        if let data = try? Data(contentsOf: cacheURL),
           let stored = try? JSONDecoder().decode([String: String].self, from: data) {
            cache = stored
        }
    }

    func countryCodes(for nodes: [ProxyNode]) async -> [UUID: String] {
        var results: [UUID: String] = [:]
        var nodesByServer: [String: [ProxyNode]] = [:]

        for node in nodes {
            if let namedCountry = CountryUtils.extractCountry(from: node.name) {
                results[node.id] = namedCountry
            } else if let cached = cache[node.server] {
                results[node.id] = cached
            } else if isPublicIPAddress(node.server) {
                nodesByServer[node.server, default: []].append(node)
            }
        }

        let servers = Array(nodesByServer.keys)
        for batchStart in stride(from: 0, to: servers.count, by: 6) {
            let batch = Array(servers[batchStart..<min(batchStart + 6, servers.count)])
            await withTaskGroup(of: (String, String?).self) { group in
                for server in batch {
                    group.addTask {
                        (server, await Self.lookup(server: server))
                    }
                }

                for await (server, countryCode) in group {
                    guard let countryCode else { continue }
                    cache[server] = countryCode
                    for node in nodesByServer[server, default: []] {
                        results[node.id] = countryCode
                    }
                }
            }
        }

        persistCache()
        return results
    }

    private static func lookup(server: String) async -> String? {
        guard let encoded = server.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://ipwho.is/\(encoded)?fields=success,country_code") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else {
                return nil
            }
            let result = try JSONDecoder().decode(CountryLookupResponse.self, from: data)
            guard result.success,
                  let code = result.countryCode?.uppercased(),
                  CountryUtils.isValidCountryCode(code) else {
                return nil
            }
            return code
        } catch {
            return nil
        }
    }

    private func persistCache() {
        guard let data = try? JSONEncoder().encode(cache) else {
            return
        }
        try? data.write(to: cacheURL, options: .atomic)
    }

    private func isPublicIPAddress(_ value: String) -> Bool {
        let parts = value.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4, parts.allSatisfy({ (0...255).contains($0) }) else {
            return false
        }
        if parts[0] == 10 || parts[0] == 127 || parts[0] == 0 {
            return false
        }
        if parts[0] == 169 && parts[1] == 254 {
            return false
        }
        if parts[0] == 172 && (16...31).contains(parts[1]) {
            return false
        }
        if parts[0] == 192 && parts[1] == 168 {
            return false
        }
        return true
    }
}

private struct CountryLookupResponse: Decodable {
    let success: Bool
    let countryCode: String?

    enum CodingKeys: String, CodingKey {
        case success
        case countryCode = "country_code"
    }
}
