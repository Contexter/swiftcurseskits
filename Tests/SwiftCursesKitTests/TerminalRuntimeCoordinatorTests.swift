import XCTest
@testable import SwiftCursesKit

final class TerminalRuntimeCoordinatorTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        CNCursesBridge.environment = .live
    }

    func testTranslateKeyCodeReturnsPrintableCharacters() {
        let coordinator = TerminalRuntimeCoordinator.shared
        let code = Int32(Character("z").asciiValue!)
        let event = coordinator._testTranslateKeyCode(code)
        guard case .character(let character)? = event else {
            return XCTFail("Expected character event")
        }
        XCTAssertEqual(character, "z")
        XCTAssertNil(coordinator._testTranslateKeyCode(-1))
        XCTAssertNil(coordinator._testTranslateKeyCode(0x80))
    }

    func testWindowHandleCloseDestroysDescriptorOnce() throws {
        let environmentDouble = TestCNCursesEnvironment()
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        guard
            let descriptor = environmentDouble.makeScreen()
                .rootWindow
                .withDescriptor({ $0 })
        else {
            return XCTFail("Expected descriptor")
        }
        let handle = WindowHandle(descriptor: descriptor, ownsLifecycle: true)
        XCTAssertFalse(handle.isClosed)
        try handle.close()
        XCTAssertTrue(handle.isClosed)
        XCTAssertEqual(environmentDouble.windowDestroyedDescriptors.count, 1)
        try handle.close()
        XCTAssertEqual(environmentDouble.windowDestroyedDescriptors.count, 1)
    }

    func testWindowAutoCloseInvokesDestroy() throws {
        let environmentDouble = TestCNCursesEnvironment()
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        guard
            let descriptor = environmentDouble.makeScreen()
                .rootWindow
                .withDescriptor({ $0 })
        else {
            return XCTFail("Expected descriptor")
        }
        var window: Window? = Window(
            handle: WindowHandle(descriptor: descriptor, ownsLifecycle: true),
            autoClose: true
        )
        XCTAssertNotNil(window)
        window = nil
        XCTAssertEqual(environmentDouble.windowDestroyedDescriptors.count, 1)
    }

    func testRuntimeProcessesKeyAndTickEvents() async throws {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.windowSize = (rows: 8, columns: 40)
        environmentDouble.colorHasSupport = false
        environmentDouble.mouseHasSupport = true
        environmentDouble.inputQueue = [Int32(Character("q").asciiValue!)]
        environmentDouble.noInputCode = -1
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let recorder = EventRecorder()
        let app = IntegrationTestApp(recorder: recorder)
        let banner = try await app.run()
        XCTAssertEqual(banner, app.banner)

        let events = await recorder.events
        XCTAssertEqual(events.count, 2)
        guard case .key(.character(let character)) = events.first else {
            return XCTFail("Expected key event")
        }
        XCTAssertEqual(character, "q")
        guard case .tick = events.last else {
            return XCTFail("Expected tick event")
        }

        XCTAssertEqual(environmentDouble.runtimeBootstrapCount, 1)
        XCTAssertEqual(environmentDouble.runtimeShutdownCount, 1)
        XCTAssertGreaterThan(environmentDouble.drawCalls.count, 0)
        XCTAssertEqual(environmentDouble.clearedCount, 1)
        XCTAssertEqual(environmentDouble.stagedCount, 1)
        XCTAssertEqual(environmentDouble.commitCount, 1)
    }

    func testMouseCaptureOptionsReflectEnvironmentMasks() {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.mouseAllEventsMask = 0x1F
        environmentDouble.mouseReportPositionMask = 0xF1
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        XCTAssertEqual(MouseCaptureOptions.buttonEvents.rawValue, 0x1F)
        XCTAssertEqual(MouseCaptureOptions.motion.rawValue, 0xF1)
    }
}

private actor EventRecorder {
    private(set) var events: [Event] = []

    func record(_ event: Event) {
        events.append(event)
    }
}

private struct IntegrationTestApp: TerminalApp {
    var recorder: EventRecorder
    var banner: String { "Integration" }

    var body: some Scene {
        Screen {
            Title("Integration")
        }
    }

    mutating func onEvent(_ event: Event, context: AppContext) async {
        await recorder.record(event)
        switch event {
        case .tick:
            await context.quit()
        case .key:
            break
        }
    }
}
