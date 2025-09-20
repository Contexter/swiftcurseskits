import Foundation
import CNCursesSupport

/// Represents the entry point for a SwiftCursesKit powered application.
public struct TerminalApp {
    /// The textual banner presented when the demo app is launched.
    public var banner: String

    /// Creates a new terminal application descriptor.
    /// - Parameter banner: The title that should be displayed when the app launches.
    public init(banner: String = "SwiftCursesKit Demo") {
        self.banner = banner
    }

    /// Prepares the terminal runtime and returns the banner text on success.
    ///
    /// This placeholder implementation allows unit tests and examples to validate the
    /// package wiring before the real ncurses integration is in place.
    /// - Returns: The banner text that callers can display to a user.
    @discardableResult
    public func run() throws -> String {
        let isReady = try CNCursesRuntime.bootstrap()
        guard isReady else {
            throw TerminalRuntimeError.bootstrapFailed
        }
        return banner
    }
}

/// Errors thrown by the terminal runtime bootstrapper.
public enum TerminalRuntimeError: Error, Equatable {
    /// Indicates that the ncurses layer failed to initialize.
    case bootstrapFailed
}
