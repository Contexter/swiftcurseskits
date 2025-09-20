/// Represents the logical terminal screen backing the root window.
public struct TerminalScreen: Sendable {
    private let rootWindowReference: Window

    /// Creates a screen instance backed by the supplied window handle.
    /// - Parameter rootHandle: The handle corresponding to the ncurses standard screen.
    internal init(rootHandle: WindowHandle) {
        self.rootWindowReference = Window(handle: rootHandle, autoClose: false)
    }

    /// The ncurses standard screen window.
    public var rootWindow: Window { rootWindowReference }

    /// The terminal size reported for the root window, if available.
    public var size: TerminalSize? { rootWindowReference.size }
}
