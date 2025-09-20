import CNCursesSupport
import Foundation

/// Owns the lifecycle of a single ncurses ``WINDOW`` instance.
public final class Window: @unchecked Sendable {
    private let handle: WindowHandle
    private let autoClose: Bool

    /// Creates a window wrapper around the specified handle.
    /// - Parameters:
    ///   - handle: The ncurses window handle managed by this wrapper.
    ///   - autoClose: Indicates whether the wrapper should close the window during deinitialization.
    internal init(handle: WindowHandle, autoClose: Bool) {
        self.handle = handle
        self.autoClose = autoClose
    }

    deinit {
        guard autoClose else { return }
        handle.closeSilently()
    }

    /// Indicates whether the underlying ncurses window has been closed.
    public var isClosed: Bool { handle.isClosed }

    /// The current terminal dimensions reported by ncurses for this window.
    public var size: TerminalSize? {
        handle.withDescriptor { descriptor in
            let size = CNCursesWindowAPI.size(of: descriptor)
            return TerminalSize(rows: size.rows, columns: size.columns)
        }
    }

    /// Closes the underlying ncurses window.
    /// - Throws: ``TerminalRuntimeError`` if ncurses reports a failure while closing the window.
    public func close() throws {
        try handle.close()
    }

    /// Executes the provided closure with access to the window handle.
    /// - Parameter body: A closure that receives the underlying ncurses descriptor.
    /// - Returns: The value produced by `body`, or `nil` when the window has no descriptor
    ///   (such as when the runtime is headless).
    internal func withDescriptor<T>(_ body: (CNCursesWindowDescriptor) throws -> T) rethrows -> T? {
        try handle.withDescriptor(body)
    }
}
