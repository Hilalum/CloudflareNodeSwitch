import Foundation

struct ClashAPIClient {
    let port: Int

    func currentOutboundTag(group: String = "auto") async throws -> String? {
        let encodedGroup = group.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? group
        guard let url = URL(string: "http://127.0.0.1:\(port)/proxies/\(encodedGroup)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let proxy = try JSONDecoder().decode(ClashProxy.self, from: data)
        return proxy.now
    }
}

private struct ClashProxy: Decodable {
    let now: String?
}
