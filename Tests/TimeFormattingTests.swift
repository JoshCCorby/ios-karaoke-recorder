import XCTest
@testable import VocalPractice

final class TimeFormattingTests: XCTestCase {
    func testZero() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(0), "00:00")
    }

    func testUnderOneMinute() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(5), "00:05")
    }

    func testMinutesAndSeconds() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(65), "01:05")
    }

    func testTruncatesFractionalSeconds() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(90.9), "01:30")
    }

    func testLargeValue() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(3599), "59:59")
    }

    func testNegativeClampsToZero() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(-10), "00:00")
    }

    func testNonFiniteClampsToZero() {
        XCTAssertEqual(TimeFormatting.minutesSeconds(.infinity), "00:00")
        XCTAssertEqual(TimeFormatting.minutesSeconds(.nan), "00:00")
    }
}
