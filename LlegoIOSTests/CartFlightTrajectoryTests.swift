import CoreGraphics
import XCTest
@testable import LlegoiOS

final class CartFlightTrajectoryTests: XCTestCase {
    func testEveryCardStartsAtItsAnchorAndArrivesAtTheCart() {
        for style in [CartFlightTrajectory.CardStyle.featured, .compact, .inline] {
            let source = CGPoint(x: 80, y: 650)
            let destination = CGPoint(x: 300, y: 60)
            let path = CartFlightTrajectory(source: source, destination: destination,
                                            viewport: CGSize(width: 390, height: 844), style: style)
            XCTAssertEqual(path.position(at: 0), source)
            XCTAssertEqual(path.position(at: 1), destination)
            XCTAssertEqual(path.position(at: -1), source)
            XCTAssertEqual(path.position(at: 2), destination)
        }
    }

    func testPathsStayOnScreenFromBothEdgesInPortraitAndLandscape() {
        for viewport in [CGSize(width: 320, height: 568), CGSize(width: 390, height: 844),
                         CGSize(width: 844, height: 390), CGSize(width: 1024, height: 1366)] {
            for style in [CartFlightTrajectory.CardStyle.featured, .compact, .inline] {
                for x in [CGFloat(24), viewport.width / 2, viewport.width - 24] {
                    for y in [CGFloat(70), viewport.height * 0.4, viewport.height - 30] {
                        let path = CartFlightTrajectory(source: CGPoint(x: x, y: y),
                            destination: CGPoint(x: viewport.width - 80, y: 60), viewport: viewport, style: style)
                        var previous = path.source
                        for step in 0...100 {
                            let point = path.position(at: CGFloat(step) / 100)
                            XCTAssertTrue(point.x.isFinite && point.y.isFinite)
                            XCTAssertTrue((0...viewport.width).contains(point.x))
                            XCTAssertTrue((0...viewport.height).contains(point.y))
                            XCTAssertLessThan(hypot(point.x - previous.x, point.y - previous.y), viewport.height / 15 + 20)
                            previous = point
                        }
                    }
                }
            }
        }
    }

    func testStyleAndScrolledOriginChangeTheTrajectory() {
        let viewport = CGSize(width: 390, height: 844)
        let destination = CGPoint(x: 300, y: 60)
        let hero = CartFlightTrajectory(source: CGPoint(x: 100, y: 500), destination: destination, viewport: viewport, style: .featured)
        let inline = CartFlightTrajectory(source: hero.source, destination: destination, viewport: viewport, style: .inline)
        let scrolled = CartFlightTrajectory(source: CGPoint(x: 200, y: 250), destination: destination, viewport: viewport, style: .featured)
        XCTAssertNotEqual(hero.position(at: 0.5), inline.position(at: 0.5))
        XCTAssertNotEqual(hero.position(at: 0.5), scrolled.position(at: 0.5))
        XCTAssertGreaterThan(hero.duration, scrolled.duration)
    }

    func testDurationRemainsComfortableAtVeryShortAndLongDistances() {
        let viewport = CGSize(width: 1024, height: 1366)
        for source in [CGPoint(x: 300, y: 60), CGPoint(x: 24, y: 1300)] {
            let path = CartFlightTrajectory(source: source, destination: CGPoint(x: 300, y: 60), viewport: viewport, style: .compact)
            XCTAssertTrue((0.48...0.88).contains(path.duration))
        }
    }
}
