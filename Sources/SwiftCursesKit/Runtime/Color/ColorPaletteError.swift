import Foundation

/// Errors thrown by the color palette when configuring ncurses color pairs.
public enum ColorPaletteError: Error, Equatable {
    /// Indicates that the terminal cannot allocate additional color pairs.
    case capacityExceeded
    /// Indicates that the terminal rejected the requested color configuration.
    /// - Parameter code: The ncurses error code that was returned.
    case ncursesCallFailed(code: Int32)
}
