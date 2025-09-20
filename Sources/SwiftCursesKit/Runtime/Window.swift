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

  /// Closes the underlying ncurses window.
  /// - Throws: ``TerminalRuntimeError`` if ncurses reports a failure while closing the window.
  public func close() throws {
    try handle.close()
  }
}
