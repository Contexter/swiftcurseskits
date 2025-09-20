import CNCursesSupport
import Foundation

/// Coordinates application execution across the ncurses runtime.
final class TerminalRuntimeCoordinator: @unchecked Sendable {
  static let shared = TerminalRuntimeCoordinator()

  private let lock = NSLock()
  private var isRunning = false
  private var shouldStop = false
  private var screenHandle: WindowHandle?

  private init() {}

  func run(app: TerminalApp) throws {
    let handle = try start()
    let screen = Screen(rootHandle: handle)
    let context = AppContext(runtime: self, screen: screen)

    var capturedError: Error?
    do {
      repeat {
        let shouldContinue = try app.frameHandler(context)
        guard shouldContinue else { break }
      } while shouldContinueRunning()
    } catch {
      capturedError = error
    }

    do {
      try stop()
    } catch {
      if capturedError == nil {
        capturedError = error
      }
    }

    if let capturedError {
      throw capturedError
    }
  }

  func requestShutdown() {
    lock.withLock { shouldStop = true }
  }

  private func shouldContinueRunning() -> Bool {
    lock.withLock { !shouldStop }
  }

  private func start() throws -> WindowHandle {
    try lock.withLock {
      if isRunning {
        throw TerminalRuntimeError.alreadyRunning
      }
      do {
        _ = try CNCursesRuntime.bootstrap()
      } catch let error as CNCursesRuntimeError {
        if case let .callFailed(name: name, code: code) = error {
          throw TerminalRuntimeError.ncursesCallFailed(
            function: name.runtimeFunctionName, code: code)
        }
        throw TerminalRuntimeError.bootstrapFailed
      } catch {
        throw TerminalRuntimeError.bootstrapFailed
      }
      if CNCursesRuntime.isHeadless {
        let handle = WindowHandle(descriptor: nil, ownsLifecycle: false)
        screenHandle = handle
        shouldStop = false
        isRunning = true
        return handle
      }
      let descriptor: CNCursesWindowDescriptor
      do {
        descriptor = try CNCursesWindowAPI.standardScreen()
      } catch {
        try? CNCursesRuntime.shutdown()
        throw TerminalRuntimeError.bootstrapFailed
      }
      let handle = WindowHandle(descriptor: descriptor, ownsLifecycle: false)
      screenHandle = handle
      shouldStop = false
      isRunning = true
      return handle
    }
  }

  private func stop() throws {
    let handle: WindowHandle? = lock.withLock {
      defer {
        screenHandle = nil
        shouldStop = false
        isRunning = false
      }
      return screenHandle
    }
    handle?.markClosed()
    do {
      try CNCursesRuntime.shutdown()
    } catch let error as CNCursesRuntimeError {
      if case let .callFailed(name: name, code: code) = error {
        throw TerminalRuntimeError.ncursesCallFailed(function: name.runtimeFunctionName, code: code)
      }
      throw TerminalRuntimeError.bootstrapFailed
    } catch {
      throw TerminalRuntimeError.bootstrapFailed
    }
  }
}
