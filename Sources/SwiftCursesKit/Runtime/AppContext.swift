/// Provides runtime information and controls to the active terminal app.
public struct AppContext: Sendable {
    private let runtime: TerminalRuntimeCoordinator
    private let screenBox: TerminalScreen

    /// Creates a new context with the supplied runtime coordinator and screen.
    /// - Parameters:
    ///   - runtime: The coordinator responsible for managing global ncurses state.
    ///   - screen: The screen presented to the application.
    internal init(runtime: TerminalRuntimeCoordinator, screen: TerminalScreen) {
        self.runtime = runtime
        self.screenBox = screen
    }

    /// The root screen associated with the running application.
    public var screen: TerminalScreen { screenBox }

    /// Requests termination of the active runtime loop.
    public func requestShutdown() {
        runtime.requestShutdown()
    }

    /// Asynchronously requests termination of the active runtime loop.
    public func quit() async {
        requestShutdown()
    }
}
