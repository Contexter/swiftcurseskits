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

    /// The detected terminal capabilities for the active session.
    public var capabilities: TerminalCapabilities { runtime.capabilitiesSnapshot() }

    /// Provides asynchronous access to the latest capability snapshot.
    /// - Returns: The most recent capability information detected by the runtime.
    public func capabilities() async -> TerminalCapabilities {
        runtime.capabilitiesSnapshot()
    }

    /// A convenience accessor for the current terminal size.
    public var terminalSize: TerminalSize? { screenBox.size }

    /// Provides access to the shared color palette for the active session.
    public var palette: ColorPalette { runtime.palette }

    /// Requests termination of the active runtime loop.
    public func requestShutdown() {
        runtime.requestShutdown()
    }

    /// Asynchronously requests termination of the active runtime loop.
    public func quit() async {
        requestShutdown()
    }

    /// Configures the mouse capture mask for the session.
    /// - Parameter options: The mask that should be applied. Pass an empty option set to disable capture.
    /// - Throws: ``MouseCaptureError`` when the runtime cannot honor the request.
    public func setMouseCapture(_ options: MouseCaptureOptions) throws {
        try runtime.setMouseCapture(options: options)
    }

    /// Enables mouse capture for the supplied set of events.
    /// - Parameter options: The mouse events to subscribe to. Defaults to ``MouseCaptureOptions.buttonEvents``.
    public func enableMouseCapture(options: MouseCaptureOptions = .buttonEvents) throws {
        try setMouseCapture(options)
    }

    /// Disables mouse capture for the active session.
    public func disableMouseCapture() throws {
        try setMouseCapture([])
    }
}
