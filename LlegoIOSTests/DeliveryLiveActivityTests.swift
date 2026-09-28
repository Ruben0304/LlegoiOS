import XCTest
import UIKit
@testable import LlegoiOS

final class DeliveryLiveActivityTests: XCTestCase {
    func test_stateMapsOrderStatusToContentAndProgress() {
        let state = DeliveryLiveActivityContentFactory.state(
            status: .inTransit, progress: 0.65, remainingDistance: "850 m", estimatedMinutes: 7
        )

        XCTAssertEqual(state.status, DeliveryStatus.inTransit.rawValue)
        XCTAssertEqual(state.statusDisplayText, DeliveryStatus.inTransit.displayText)
        XCTAssertEqual(state.statusIcon, DeliveryStatus.inTransit.icon)
        XCTAssertEqual(state.progressValue, 0.65)
        XCTAssertEqual(state.remainingDistance, "850 m")
        XCTAssertEqual(state.estimatedMinutes, 7)
    }

    func test_startFallbackUsesSmallerPayloadAfterEarlierAttemptsFail() {
        var attempts: [String] = []
        let index = LiveActivityFallback.firstSuccessfulAttempt(["full", "small", "minimal"]) { candidate in
            attempts.append(candidate)
            return candidate == "minimal"
        }

        XCTAssertEqual(attempts, ["full", "small", "minimal"])
        XCTAssertEqual(index, 2)
        XCTAssertNil(LiveActivityFallback.firstSuccessfulAttempt([1, 2]) { _ in false })
    }

    func test_endBuildsDeliveredAndCancelledFinalStates() {
        let delivered = DeliveryLiveActivityContentFactory.finalState(delivered: true)
        XCTAssertEqual(delivered.status, DeliveryStatus.delivered.rawValue)
        XCTAssertEqual(delivered.statusDisplayText, "¡Entregado!")
        XCTAssertEqual(delivered.statusIcon, "checkmark.seal.fill")
        XCTAssertEqual(delivered.progressValue, 1)
        XCTAssertEqual(delivered.remainingDistance, "Llegó")
        XCTAssertEqual(delivered.estimatedMinutes, 0)

        let cancelled = DeliveryLiveActivityContentFactory.finalState(delivered: false)
        XCTAssertEqual(cancelled.status, DeliveryStatus.cancelled.rawValue)
        XCTAssertEqual(cancelled.statusDisplayText, "Cancelado")
        XCTAssertEqual(cancelled.progressValue, 0)
    }

    func test_imageThumbnailIsResizedAndCompressedUnderLimit() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 120))
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 240, height: 120))
        }

        let data = LiveActivityImageProcessor.compressedThumbnail(from: image, maxSide: 28, maxBytes: 1_800)
        XCTAssertNotNil(data)
        XCTAssertLessThanOrEqual(data?.count ?? Int.max, 1_800)
        let thumbnail = data.flatMap(UIImage.init(data:))
        XCTAssertLessThanOrEqual(thumbnail?.size.width ?? .infinity, 28)
        XCTAssertLessThanOrEqual(thumbnail?.size.height ?? .infinity, 28)
    }
}
