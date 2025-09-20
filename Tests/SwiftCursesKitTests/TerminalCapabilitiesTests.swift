import XCTest
@testable import SwiftCursesKit

final class TerminalCapabilitiesTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        CNCursesBridge.environment = .live
    }

    func testInspectorFallsBackWhenColorInitializationFails() {
        enum SampleError: Error { case failure }

        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.runtimeIsHeadless = false
        environmentDouble.colorHasSupport = true
        environmentDouble.colorStartThrows = SampleError.failure
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let capabilities = TerminalCapabilitiesInspector.inspect()
        XCTAssertFalse(capabilities.supportsColor)
        XCTAssertEqual(capabilities.colorCount, 0)
        XCTAssertEqual(capabilities.colorPairCount, 0)
        XCTAssertFalse(capabilities.supportsDefaultColors)
        XCTAssertFalse(capabilities.supportsDynamicColorChanges)
    }

    func testInspectorReportsMouseSupportWhenAvailable() {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.runtimeIsHeadless = false
        environmentDouble.mouseHasSupport = true
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let capabilities = TerminalCapabilitiesInspector.inspect()
        XCTAssertTrue(capabilities.supportsMouse)
    }

    func testInspectorReportsHeadlessWhenRuntimeIsHeadless() {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.runtimeIsHeadless = true
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let capabilities = TerminalCapabilitiesInspector.inspect()
        XCTAssertTrue(capabilities.isHeadless)
        XCTAssertFalse(capabilities.supportsMouse)
    }
}
