import Foundation

/// Represents the current terminal dimensions in rows and columns.
public struct TerminalSize: Equatable, Sendable {
    /// The number of character rows available.
    public var rows: Int
    /// The number of character columns available.
    public var columns: Int

    /// Creates a new terminal size descriptor.
    /// - Parameters:
    ///   - rows: The number of rows.
    ///   - columns: The number of columns.
    public init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }
}
