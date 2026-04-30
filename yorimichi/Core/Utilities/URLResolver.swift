import Foundation

enum URLResolver {
    static func resolveRedirect(_ urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.url?.absoluteString ?? response.url?.absoluteString
        } catch {
            return nil
        }
    }
}
