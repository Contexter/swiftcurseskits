import Foundation

/// Represents a configured ncurses color pair identifier.
public struct ColorPair: Sendable, Hashable {
    /// The raw ncurses color pair identifier.
    public let rawValue: Int16

    /// Creates a new color pair wrapper.
    /// - Parameter rawValue: The ncurses color pair identifier.
    public init(rawValue: Int16) {
        self.rawValue = rawValue
    }

    /// The default color pair configured by ncurses.
    public static var `default`: ColorPair { ColorPair(rawValue: 0) }
}
