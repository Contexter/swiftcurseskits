import XCTest

@testable import SwiftCursesKit

final class TerminalAppTests: XCTestCase {
  func testRunReturnsBanner() throws {
    let app = TerminalApp(banner: "Test Banner")
    let output = try app.run()
    XCTAssertEqual(output, "Test Banner")
  }

  func testFrameHandlerRunsUntilContextRequestsShutdown() throws {
    var iterations = 0
    let app = TerminalApp { context in
      iterations += 1
      context.requestShutdown()
      return true
    }
    _ = try app.run()
    XCTAssertEqual(iterations, 1)
  }
}
