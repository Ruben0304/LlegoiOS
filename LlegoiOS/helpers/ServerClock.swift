import Foundation

/// Syncs with the server clock once at startup to correct for device clock drift.
/// Use `ServerClock.shared.now` instead of `Date()` wherever deadline comparisons happen.
@MainActor
final class ServerClock {
    static let shared = ServerClock()

    // Positive = server ahead, negative = server behind
    private var offsetSeconds: Double = 0

    var now: Date {
        Date().addingTimeInterval(offsetSeconds)
    }

    func sync() async {
        let url = URL(string: "\(ApolloClientManager.baseURL)/time")!
        let requestedAt = Date()

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let receivedAt = Date()

            let response = try JSONDecoder().decode(ServerTimeResponse.self, from: data)
            guard let serverDate = ISO8601DateFormatter.flexible.date(from: response.utc) else { return }

            let networkLatency = receivedAt.timeIntervalSince(requestedAt) / 2
            let serverAtMidpoint = serverDate.addingTimeInterval(-networkLatency)
            offsetSeconds = serverAtMidpoint.timeIntervalSince(requestedAt)
        } catch {
            // Silently fall back to device time if sync fails
        }
    }

    private init() {}
}

private struct ServerTimeResponse: Decodable {
    let utc: String
}

private extension ISO8601DateFormatter {
    nonisolated(unsafe) static let flexible: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
