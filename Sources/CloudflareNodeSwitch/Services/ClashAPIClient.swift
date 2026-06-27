import Foundation

struct ClashAPIClient {
    let port: Int

    func currentOutboundTag(group: String = "auto") async throws -> String? {
        try await snapshot(group: group).currentTag
    }

    func snapshot(group: String = "auto") async throws -> ClashProxySnapshot {
        guard let url = URL(string: "http://127.0.0.1:\(port)/proxies") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let responseBody = try JSONDecoder().decode(ClashProxiesResponse.self, from: data)
        let delays = responseBody.proxies.reduce(into: [String: Int]()) { result, entry in
            if let delay = entry.value.history?.last?.delay, delay > 0 {
                result[entry.key] = delay
            }
        }
        return ClashProxySnapshot(currentTag: responseBody.proxies[group]?.now, delays: delays)
    }
}

struct ClashProxySnapshot {
    let currentTag: String?
    let delays: [String: Int]
}

private struct ClashProxiesResponse: Decodable {
    let proxies: [String: ClashProxy]
}

private struct ClashProxy: Decodable {
    let now: String?
    let history: [ClashHistory]?
}

private struct ClashHistory: Decodable {
    let delay: Int
}
