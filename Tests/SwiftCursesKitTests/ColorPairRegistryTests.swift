import XCTest
@testable import SwiftCursesKit

final class ColorPairRegistryTests: XCTestCase {
    private enum TestError: Error { case failure }

    func testInitializationFailureDoesNotCachePair() throws {
        let testEnvironment = TestCNCursesEnvironment()
        testEnvironment.colorHasSupport = true
        testEnvironment.colorCountValue = 8
        testEnvironment.colorPairCountValue = 8
        testEnvironment.colorEnableDefaultColors = true

        let originalEnvironment = CNCursesBridge.environment
        defer { CNCursesBridge.environment = originalEnvironment }
        CNCursesBridge.environment = testEnvironment.makeEnvironment()

        let registry = ColorPairRegistry()
        registry.updateCapabilities(
            TerminalCapabilities(
                isHeadless: false,
                supportsColor: true,
                colorCount: 8,
                colorPairCount: 8,
                supportsDefaultColors: true,
                supportsDynamicColorChanges: false,
                supportsMouse: false
            )
        )

        let configuration = ColorPairConfiguration(
            foreground: .red,
            background: .blue
        )

        testEnvironment.colorInitializeError = TestError.failure

        XCTAssertThrowsError(try registry.pair(for: configuration)) { error in
            XCTAssertEqual(error as? ColorPaletteError, .ncursesCallFailed(code: -1))
        }
        XCTAssertTrue(testEnvironment.initializedPairs.isEmpty)

        testEnvironment.colorInitializeError = nil

        let allocatedPair = try registry.pair(for: configuration)
        XCTAssertEqual(allocatedPair.rawValue, 1)
        XCTAssertEqual(testEnvironment.initializedPairs.count, 1)
        XCTAssertEqual(testEnvironment.initializedPairs.first?.0, allocatedPair.rawValue)

        let cachedPair = try registry.pair(for: configuration)
        XCTAssertEqual(cachedPair, allocatedPair)
        XCTAssertEqual(testEnvironment.initializedPairs.count, 1)
    }
}
