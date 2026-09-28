import XCTest
@testable import LlegoiOS

final class OrderTrackingRealtimeClientTests: XCTestCase {
    func test_streamSendsConnectionInitAndSubscribeAndParsesNext() async throws {
        let socket = FakeOrderTrackingSocket(messages: [
            .text(#"{"type":"connection_ack"}"#),
            .text(#"{"id":"order-tracking-ord-1","type":"next","payload":{"data":{"orderTrackingStream":"malformed"}}}"#),
            .text(#"{"id":"order-tracking-ord-1","type":"next","payload":{"data":{"orderTrackingStream":{"estimatedMinutes":8,"distanceKm":1.25,"deliveryPersonLocation":{"type":"Point","coordinates":[-82.3,23.1]},"order":{"id":"ord-1","status":"IN_TRANSIT","estimatedMinutesRemaining":9}}}}}"#),
            .text(#"{"id":"order-tracking-ord-1","type":"complete"}"#)
        ])
        let factory = FakeOrderTrackingSocketFactory(socket: socket)
        let client = OrderTrackingRealtimeClient(baseURL: "https://api.example.test", socketFactory: factory)
        let events = RealtimeEventRecorder()

        try await client.streamOrderUpdates(orderId: "ord-1", jwt: "jwt-test") { events.append($0) }

        XCTAssertTrue(socket.didResume)
        XCTAssertTrue(socket.didCancel)
        XCTAssertEqual(factory.url?.absoluteString, "wss://api.example.test/graphql")
        XCTAssertEqual(factory.protocols, ["graphql-transport-ws"])
        let sent = socket.sent.compactMap { message -> [String: Any]? in
            guard case .text(let text) = message,
                  let data = text.data(using: .utf8) else { return nil }
            return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        }
        XCTAssertEqual(sent.map { $0["type"] as? String }, ["connection_init", "subscribe"])
        let initPayload = sent.first?["payload"] as? [String: String]
        XCTAssertEqual(initPayload?["Authorization"], "Bearer jwt-test")
        let subscription = sent.last?["payload"] as? [String: Any]
        XCTAssertEqual(subscription?["operationName"] as? String, "OrderTrackingStream")
        XCTAssertEqual((subscription?["variables"] as? [String: String])?["orderId"], "ord-1")
        XCTAssertEqual(events.values.count, 1)
        XCTAssertEqual(events.values.first?.orderId, "ord-1")
        XCTAssertEqual(events.values.first?.statusRaw, "IN_TRANSIT")
        XCTAssertEqual(events.values.first?.estimatedMinutes, 8)
        XCTAssertEqual(events.values.first?.distanceKm, 1.25)
        XCTAssertEqual(events.values.first?.deliveryPersonCoordinates, [-82.3, 23.1])
    }

    func test_streamPropagatesSocketErrorsAndCancelsSocket() async {
        let socket = FakeOrderTrackingSocket(messages: [.text(#"{"type":"connection_ack"}"#)], receiveError: TestSocketError.disconnected)
        let client = OrderTrackingRealtimeClient(baseURL: "http://api.example.test", socketFactory: FakeOrderTrackingSocketFactory(socket: socket))

        do {
            try await client.streamOrderUpdates(orderId: "ord-2", jwt: "jwt") { _ in }
            XCTFail("Se esperaba el error de desconexión")
        } catch {
            XCTAssertTrue(error is TestSocketError)
        }
        XCTAssertTrue(socket.didCancel)
    }

    func test_streamPropagatesGraphQLServerErrors() async {
        let socket = FakeOrderTrackingSocket(messages: [
            .text(#"{"type":"connection_ack"}"#),
            .text(#"{"id":"order-tracking-ord-3","type":"error","payload":[{"message":"forbidden"}]}"#)
        ])
        let client = OrderTrackingRealtimeClient(baseURL: "https://api.example.test", socketFactory: FakeOrderTrackingSocketFactory(socket: socket))

        do {
            try await client.streamOrderUpdates(orderId: "ord-3", jwt: "jwt") { _ in }
            XCTFail("Se esperaba un error GraphQL")
        } catch {
            XCTAssertEqual(error as? OrderTrackingRealtimeError, .serverReportedError)
        }
        XCTAssertTrue(socket.didCancel)
    }

    func test_streamRejectsNonAcknowledgementHandshake() async {
        let socket = FakeOrderTrackingSocket(messages: [.text(#"{"type":"ka"}"#)])
        let client = OrderTrackingRealtimeClient(baseURL: "https://api.example.test", socketFactory: FakeOrderTrackingSocketFactory(socket: socket))

        do {
            try await client.streamOrderUpdates(orderId: "ord-4", jwt: "jwt") { _ in }
            XCTFail("Se esperaba el rechazo del handshake")
        } catch {
            XCTAssertEqual(error as? OrderTrackingRealtimeError, .serverRejectedConnection)
        }
        XCTAssertTrue(socket.didCancel)
    }
}

private enum TestSocketError: Error { case disconnected }

private final class RealtimeEventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [OrderTrackingRealtimeEvent] = []
    var values: [OrderTrackingRealtimeEvent] { lock.lock(); defer { lock.unlock() }; return storage }
    func append(_ event: OrderTrackingRealtimeEvent) { lock.lock(); storage.append(event); lock.unlock() }
}

private final class FakeOrderTrackingSocketFactory: OrderTrackingWebSocketFactory, @unchecked Sendable {
    let socket: FakeOrderTrackingSocket
    var url: URL?
    var protocols: [String] = []
    init(socket: FakeOrderTrackingSocket) { self.socket = socket }
    func makeSocket(url: URL, protocols: [String]) -> OrderTrackingWebSocket {
        self.url = url; self.protocols = protocols; return socket
    }
}

private final class FakeOrderTrackingSocket: OrderTrackingWebSocket, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [OrderTrackingSocketMessage]
    private let receiveError: Error?
    private(set) var sent: [OrderTrackingSocketMessage] = []
    private(set) var didResume = false
    private(set) var didCancel = false
    init(messages: [OrderTrackingSocketMessage], receiveError: Error? = nil) {
        self.messages = messages; self.receiveError = receiveError
    }
    func resume() { lock.lock(); didResume = true; lock.unlock() }
    func cancel() { lock.lock(); didCancel = true; lock.unlock() }
    func send(_ message: OrderTrackingSocketMessage) async throws {
        appendSent(message)
    }
    func receive() async throws -> OrderTrackingSocketMessage {
        try takeNextMessage()
    }
    private func appendSent(_ message: OrderTrackingSocketMessage) {
        lock.lock(); sent.append(message); lock.unlock()
    }
    private func takeNextMessage() throws -> OrderTrackingSocketMessage {
        lock.lock(); defer { lock.unlock() }
        if !messages.isEmpty { return messages.removeFirst() }
        if let receiveError { throw receiveError }
        throw TestSocketError.disconnected
    }
}
