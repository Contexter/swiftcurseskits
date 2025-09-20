import Foundation

/// Errors thrown by the terminal runtime bootstrapper and coordinator.
public enum TerminalRuntimeError: Error, Equatable {
  /// Indicates that the ncurses layer failed to initialize.
  case bootstrapFailed
  /// The runtime was asked to start while already executing an application.
  case alreadyRunning
  /// An ncurses call returned a failure code.
  /// - Parameters:
  ///   - function: The ncurses API name that failed.
  ///   - code: The error code reported by ncurses.
  case ncursesCallFailed(function: String, code: Int32)
}
