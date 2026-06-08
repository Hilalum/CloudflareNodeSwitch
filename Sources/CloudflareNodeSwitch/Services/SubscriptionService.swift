import Foundation

struct SubscriptionService {
    func fetch(from urlString: String) async throws -> [ProxyNode] {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let text = String(decoding: data, as: UTF8.self)
        return try SubscriptionParser().parse(text)
    }
}
