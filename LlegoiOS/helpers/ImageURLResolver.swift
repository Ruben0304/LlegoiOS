import Foundation

enum ImageURLResolver {
    static func resolve(_ raw: String?) -> URL? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else {
            return nil
        }

        if let directURL = URL(string: trimmed) {
            return directURL
        }

        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedURL = URL(string: encoded) {
            return encodedURL
        }

        return nil
    }
}
