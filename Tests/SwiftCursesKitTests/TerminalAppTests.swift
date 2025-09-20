import XCTest
@testable import SwiftCursesKit

final class TerminalAppTests: XCTestCase {
    func testRunReturnsBanner() throws {
        let app = TerminalApp(banner: "Test Banner")
        let output = try app.run()
        XCTAssertEqual(output, "Test Banner")
    }
}
