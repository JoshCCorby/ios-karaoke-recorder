import XCTest
@testable import VocalPractice

final class KaraokeTakeCoordinatorTests: XCTestCase {

    private func makeCoordinator(sessionActive: Bool = true) -> (KaraokeTakeCoordinator, AudioSessionManager) {
        let manager = AudioSessionManager(autoConfigure: false)
        manager.isAudioSessionActive = sessionActive
        let coordinator = KaraokeTakeCoordinator(sessionManager: manager)
        return (coordinator, manager)
    }

    /// Lets queued `.receive(on: .main)` deliveries flush before assertions.
    private func drainMainQueue() {
        let exp = expectation(description: "main queue drained")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }

    func testInitialState() {
        let (coordinator, _) = makeCoordinator()
        XCTAssertFalse(coordinator.isTakeActive)
        XCTAssertFalse(coordinator.isTakePaused)
        XCTAssertNil(coordinator.pauseReason)
        XCTAssertNil(coordinator.lastError)
    }

    func testCanStartTakeRequiresActiveSession() {
        let (active, _) = makeCoordinator(sessionActive: true)
        XCTAssertTrue(active.canStartTake)

        let (inactive, _) = makeCoordinator(sessionActive: false)
        XCTAssertFalse(inactive.canStartTake)
    }

    func testInterruptionBeganPausesActiveTake() {
        let (coordinator, manager) = makeCoordinator()
        coordinator.isTakeActive = true

        manager.interruptionPhase = .began
        drainMainQueue()

        XCTAssertTrue(coordinator.isTakePaused)
        XCTAssertEqual(coordinator.pauseReason, .interruption)
        XCTAssertFalse(coordinator.isTakeActive)
    }

    func testInterruptionBeganIgnoredWhenNoActiveTake() {
        let (coordinator, manager) = makeCoordinator()

        manager.interruptionPhase = .began
        drainMainQueue()

        XCTAssertFalse(coordinator.isTakePaused)
        XCTAssertNil(coordinator.pauseReason)
    }

    func testHeadphoneRemovalPausesActiveTake() {
        let (coordinator, manager) = makeCoordinator()
        coordinator.isTakeActive = true

        manager.routeChangeReason = .oldDeviceUnavailable
        drainMainQueue()

        XCTAssertTrue(coordinator.isTakePaused)
        XCTAssertEqual(coordinator.pauseReason, .headphonesRemoved)
    }

    func testUnrelatedRouteChangeDoesNotPause() {
        let (coordinator, manager) = makeCoordinator()
        coordinator.isTakeActive = true

        manager.routeChangeReason = .newDeviceAvailable
        drainMainQueue()

        XCTAssertFalse(coordinator.isTakePaused)
    }

    func testInterruptionEndedWithoutResumeKeepsTakePaused() {
        let (coordinator, manager) = makeCoordinator()
        coordinator.isTakeActive = true

        manager.interruptionPhase = .began
        drainMainQueue()
        XCTAssertTrue(coordinator.isTakePaused)

        manager.interruptionPhase = .ended(shouldResume: false)
        drainMainQueue()

        // Without shouldResume the take must stay paused for the user to resume manually.
        XCTAssertTrue(coordinator.isTakePaused)
    }
}
