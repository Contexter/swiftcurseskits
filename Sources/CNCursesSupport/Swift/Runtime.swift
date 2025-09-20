import CNCursesSupportShims
import Foundation

#if os(Linux)
  import Glibc
#endif

/// Errors that can be thrown while configuring the ncurses runtime.
package enum CNCursesRuntimeError: Error, Equatable {
  /// Indicates that the process locale could not be configured for wide characters.
  case localeUnavailable
  /// The ncurses library failed to produce a usable screen handle.
  case initializationFailed
  /// A specific ncurses call returned an error code.
  case callFailed(name: StaticString, code: Int32)

  package static func == (lhs: CNCursesRuntimeError, rhs: CNCursesRuntimeError) -> Bool {
    switch (lhs, rhs) {
    case (.localeUnavailable, .localeUnavailable),
      (.initializationFailed, .initializationFailed):
      return true
    case let (
      .callFailed(name: lhsName, code: lhsCode), .callFailed(name: rhsName, code: rhsCode)
    ):
      return lhsCode == rhsCode && lhsName.asComparableKey == rhsName.asComparableKey
    default:
      return false
    }
  }
}

package enum CNCursesRuntime {
  private static let state = CNCursesRuntimeState()

  /// Prepares the terminal environment for interactive rendering.
  /// - Returns: `true` when initialization succeeds; otherwise throws.
  package static func bootstrap() throws -> Bool {
    try state.bootstrap()
    return true
  }

  /// Restores the terminal to its previous state.
  package static func shutdown() throws {
    try state.shutdown()
  }

  /// Indicates whether the runtime is operating without a backing terminal.
  package static var isHeadless: Bool {
    state.isHeadlessFlag
  }
}

private final class CNCursesRuntimeState: @unchecked Sendable {
  private var screen: CNCursesWindow?
  private var isHeadless = false
  private var exitHookRegistered = false
  private let lock = NSLock()

  func bootstrap() throws {
    try lock.withLock {
      if screen != nil || isHeadless {
        return
      }

      if !TerminalCapabilities.isInteractive {
        isHeadless = true
        return
      }

      try LocaleConfigurator.ensureWideCharacterLocale()

      let newScreen = try CNCursesWindow.standardScreen()
      do {
        try newScreen.prepareForInteractiveUse()
      } catch {
        _ = cncurses_endwin()
        throw error
      }

      screen = newScreen
      registerExitHookIfNeeded()
    }
  }

  func shutdown() throws {
    try lock.withLock {
      if isHeadless {
        isHeadless = false
        return
      }

      guard screen != nil else {
        return
      }
      try CNCursesCall.check(result: cncurses_endwin(), name: "endwin")
      screen = nil
    }
  }

  private func registerExitHookIfNeeded() {
    guard !exitHookRegistered else {
      return
    }
    #if os(Linux)
      Glibc.atexit(swiftCNCursesCleanup)
    #else
      _ = cncurses_register_exit_hook(swiftCNCursesCleanup)
    #endif
    exitHookRegistered = true
  }

  var isHeadlessFlag: Bool {
    lock.withLock { isHeadless }
  }
}

private struct CNCursesWindow {
  let rawPointer: UnsafeMutableRawPointer

  static func standardScreen() throws -> CNCursesWindow {
    guard let pointer = cncurses_initscr() else {
      throw CNCursesRuntimeError.initializationFailed
    }
    return CNCursesWindow(rawPointer: pointer)
  }

  func prepareForInteractiveUse() throws {
    try CNCursesCall.check(result: cncurses_cbreak(), name: "cbreak")
    try CNCursesCall.check(result: cncurses_noecho(), name: "noecho")
    try CNCursesCall.check(result: cncurses_keypad(rawPointer, true), name: "keypad")
    try CNCursesCall.check(result: cncurses_nodelay(rawPointer, true), name: "nodelay")
    try CNCursesCall.check(result: cncurses_erase(), name: "erase")
    try CNCursesCall.check(result: cncurses_refresh(), name: "refresh")
  }
}

private enum LocaleConfigurator {
  static func ensureWideCharacterLocale() throws {
    #if os(Linux)
      let result = Glibc.setlocale(LC_ALL, "")
    #else
      let result = cncurses_setlocale(cncurses_lc_all(), "")
    #endif
    guard result != nil else {
      throw CNCursesRuntimeError.localeUnavailable
    }
  }
}

package enum CNCursesCall {
  private static let successCode = cncurses_ok()

  static func check(result: Int32, name: StaticString) throws {
    if result == successCode {
      return
    }
    throw CNCursesRuntimeError.callFailed(name: name, code: result)
  }
}

private enum TerminalCapabilities {
  static var isInteractive: Bool {
    #if os(Linux)
      return Glibc.isatty(STDIN_FILENO) != 0 && Glibc.isatty(STDOUT_FILENO) != 0
    #else
      return cncurses_isatty(STDIN_FILENO) && cncurses_isatty(STDOUT_FILENO)
    #endif
  }
}

extension NSLock {
  @inline(__always)
  fileprivate func withLock<T>(_ body: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try body()
  }
}

@_cdecl("swiftCNCursesCleanup")
private func swiftCNCursesCleanup() {
  if !cncurses_is_endwin() {
    _ = cncurses_endwin()
  }
}

extension StaticString {
  fileprivate var asComparableKey: String {
    String(describing: self)
  }
}
