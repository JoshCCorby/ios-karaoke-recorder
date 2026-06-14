import XCTest
@testable import VocalPractice

final class RecorderMeterTests: XCTestCase {
    func testFullScalePowerMapsToOne() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: 0), 1.0, accuracy: 0.0001)
    }

    func testSilenceFloorMapsToZero() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: -60), 0.0, accuracy: 0.0001)
    }

    func testBelowFloorClampsToZero() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: -160), 0.0, accuracy: 0.0001)
    }

    func testAboveFullScaleClampsToOne() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: 10), 1.0, accuracy: 0.0001)
    }

    func testMidpoint() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: -30), 0.5, accuracy: 0.0001)
    }

    func testNonFiniteIsZero() {
        XCTAssertEqual(RecorderViewModel.normalizedLevel(fromPower: .nan), 0.0, accuracy: 0.0001)
    }
}
