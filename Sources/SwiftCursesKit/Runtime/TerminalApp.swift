import Foundation

/// Describes the entry point for an ncurses powered terminal experience.
///
/// A ``TerminalApp`` encapsulates the high-level configuration of a SwiftCurses
/// application including the initial banner shown during startup and the frame
/// handler executed by the runtime coordinator. The handler is invoked for each
/// pass of the main loop until it returns `false` or the app requests a
/// shutdown through ``AppContext/requestShutdown()``.
public struct TerminalApp {
  /// Represents a single iteration of the application's main loop.
  ///
  /// Return `true` to keep processing future iterations or `false` to exit once
  /// the current iteration completes.
  public typealias FrameHandler = (_ context: AppContext) throws -> Bool

  /// The textual banner presented when the application launches.
  public var banner: String

  /// The closure invoked on every iteration of the main loop.
  public var frameHandler: FrameHandler

  /// Creates a new terminal application descriptor.
  /// - Parameters:
  ///   - banner: The title that should be displayed when the app launches.
  ///   - frameHandler: A closure executed for each pass of the main loop.
  ///     Return `true` to continue running or `false` to finish execution.
  public init(
    banner: String = "SwiftCursesKit Demo", frameHandler: @escaping FrameHandler = { _ in false }
  ) {
    self.banner = banner
    self.frameHandler = frameHandler
  }

  /// Boots the terminal runtime and executes the main loop.
  /// - Returns: The banner text that callers can display to a user.
  /// - Throws: ``TerminalRuntimeError`` when the runtime cannot be started or shut down cleanly.
  @discardableResult
  public func run() throws -> String {
    try TerminalRuntimeCoordinator.shared.run(app: self)
    return banner
  }
}
