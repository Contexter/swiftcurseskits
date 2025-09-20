import CNCursesSupport
import Foundation

/// Represents a color index supported by the underlying terminal.
public struct TerminalColor: Sendable, Hashable {
    /// The raw ncurses color index.
    public let rawValue: Int16

    /// Creates a color from the specified ncurses color index.
    /// - Parameter rawValue: The color index to represent.
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    /// Creates a color from an arbitrary integer value.
    /// - Parameter index: The ncurses color index.
    public init(index: Int) {
        self.rawValue = Int16(index)
    }

    /// The standard ncurses black color.
    public static var black: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.blackIdentifier())
    }

    /// The standard ncurses red color.
    public static var red: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.redIdentifier())
    }

    /// The standard ncurses green color.
    public static var green: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.greenIdentifier())
    }

    /// The standard ncurses yellow color.
    public static var yellow: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.yellowIdentifier())
    }

    /// The standard ncurses blue color.
    public static var blue: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.blueIdentifier())
    }

    /// The standard ncurses magenta color.
    public static var magenta: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.magentaIdentifier())
    }

    /// The standard ncurses cyan color.
    public static var cyan: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.cyanIdentifier())
    }

    /// The standard ncurses white color.
    public static var white: TerminalColor {
        TerminalColor(rawValue: CNCursesColorAPI.whiteIdentifier())
    }

    /// Validates whether the color value is within the specified capability bounds.
    /// - Parameter capabilities: The terminal capabilities describing color support.
    /// - Returns: `true` if the color index can be used with the provided capabilities.
    public func isSupported(by capabilities: TerminalCapabilities) -> Bool {
        let index = Int(rawValue)
        return index >= 0 && index < capabilities.colorCount
    }
}
