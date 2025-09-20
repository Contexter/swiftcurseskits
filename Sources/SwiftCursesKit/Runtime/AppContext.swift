/// Provides runtime information and controls to the active terminal app.
public struct AppContext: Sendable {
  private let runtime: TerminalRuntimeCoordinator
  private let screenBox: TerminalScreen
  private let eventSource: TerminalEventSource

  /// Creates a new context with the supplied runtime coordinator and screen.
  /// - Parameters:
  ///   - runtime: The coordinator responsible for managing global ncurses state.
  ///   - screen: The screen presented to the application.
  ///   - eventSource: The event dispatcher responsible for producing runtime events.
  internal init(
    runtime: TerminalRuntimeCoordinator, screen: TerminalScreen, eventSource: TerminalEventSource
  ) {
    self.runtime = runtime
    self.screenBox = screen
    self.eventSource = eventSource
  }

  /// The root screen associated with the running application.
  public var screen: TerminalScreen { screenBox }

  /// Provides direct access to the asynchronous stream of runtime events.
  public var events: EventStream { eventSource.events() }

  /// Requests termination of the active runtime loop.
  public func requestShutdown() {
    runtime.requestShutdown()
  }

  /// Asynchronously requests termination of the active runtime loop.
  public func quit() async {
    requestShutdown()
  }

  /// Schedules periodic tick events to drive animations or background tasks.
  /// - Parameters:
  ///   - interval: The cadence between ticks.
  ///   - immediate: Indicates whether an initial tick should be emitted immediately.
  /// - Returns: A `Task` handle that can be cancelled to stop the scheduled ticks.
  @discardableResult
  public func scheduleTicks(every interval: Duration, immediate: Bool = false) -> Task<Void, Never>
  {
    eventSource.scheduleTicks(every: interval, immediate: immediate)
  }
}
