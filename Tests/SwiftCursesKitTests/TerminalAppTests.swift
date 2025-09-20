import XCTest

@testable import SwiftCursesKit

final class TerminalAppTests: XCTestCase {
  func testRunReturnsBanner() async throws {
    let app = StaticTerminalApp()
    let output = try await app.run()
    XCTAssertEqual(output, "Test Banner")
  }

  func testOnEventReceivesTickAndStops() async throws {
    let recorder = TickRecorder()
    let app = CountingTerminalApp(recorder: recorder)
    _ = try await app.run()
    let ticks = await recorder.current()
    XCTAssertEqual(ticks, 1)
  }
}

private struct StaticTerminalApp: TerminalApp {
  var banner: String { "Test Banner" }

  var body: some Scene {
    Screen {
      Title("Test Banner")
    }
  }

  mutating func onEvent(_ event: Event, context: AppContext) async {
    if case .tick = event {
      await context.quit()
    }
  }
}

private struct CountingTerminalApp: TerminalApp {
  var recorder: TickRecorder

  var body: some Scene {
    Screen {
      Title("Tick Counter")
    }
  }

  mutating func onEvent(_ event: Event, context: AppContext) async {
    if case .tick = event {
      await recorder.increment()
      await context.quit()
    }
  }
}

private actor TickRecorder {
  private var count = 0

  func increment() {
    count += 1
  }

  func current() -> Int {
    count
  }
}
