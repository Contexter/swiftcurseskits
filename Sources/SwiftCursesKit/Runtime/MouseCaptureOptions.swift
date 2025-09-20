import CNCursesSupport
import Foundation

/// Represents the set of mouse events that should be captured by ncurses.
public struct MouseCaptureOptions: OptionSet, Sendable {
    public let rawValue: UInt

    /// Creates a new option set.
    /// - Parameter rawValue: The underlying ncurses mask value.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Captures all mouse button events supported by ncurses.
    public static let buttonEvents = MouseCaptureOptions(rawValue: CNCursesMouseAPI.allEventsMask())

    /// Enables reporting of mouse motion while buttons are pressed.
    public static let motion = MouseCaptureOptions(rawValue: CNCursesMouseAPI.reportPositionMask())

    /// Captures all available mouse events.
    public static let all: MouseCaptureOptions = [.buttonEvents, .motion]
}

/// Errors produced while configuring mouse capture.
public enum MouseCaptureError: Error, Equatable {
    /// Indicates that mouse capture was requested while the runtime is not active.
    case runtimeInactive
    /// Indicates that the terminal does not support mouse events.
    case unsupported
    /// Indicates that ncurses returned an error code.
    /// - Parameter code: The ncurses error code returned from `mousemask`.
    case ncursesCallFailed(code: Int32)
}
