import Foundation

/// Describes a collection of color roles that can be resolved against a ``ColorPalette``.
public struct TerminalTheme<Role: Hashable & Sendable>: Sendable {
    /// Represents a single themed color definition.
    public struct Entry: Sendable, Hashable {
        /// The preferred color configuration when the terminal supports colors.
        public var configuration: ColorPairConfiguration
        /// The fallback configuration used when colors are unavailable.
        public var fallback: ColorPairConfiguration

        /// Creates a themed entry.
        /// - Parameters:
        ///   - configuration: The preferred color pair configuration.
        ///   - fallback: The configuration applied when colors are unavailable. Defaults to ``ColorPairConfiguration.monochrome``.
        public init(
            configuration: ColorPairConfiguration,
            fallback: ColorPairConfiguration = .monochrome
        ) {
            self.configuration = configuration
            self.fallback = fallback
        }
    }

    private let entries: [Role: Entry]

    /// Creates a theme with the supplied entries.
    /// - Parameter entries: A dictionary mapping role identifiers to theme entries.
    public init(entries: [Role: Entry]) {
        self.entries = entries
    }

    /// Resolves the color pair for the provided role using the supplied palette.
    /// - Parameters:
    ///   - role: The logical role to resolve.
    ///   - palette: The palette that manages ncurses color pairs.
    /// - Returns: The resolved color pair.
    public func colorPair(for role: Role, using palette: ColorPalette) throws -> ColorPair {
        let capabilities = palette.capabilities
        guard capabilities.supportsColor else {
            let entry = entries[role]
            return try palette.pair(for: entry?.fallback ?? .monochrome)
        }
        guard let entry = entries[role] else {
            return try palette.pair(for: .monochrome)
        }
        if entry.configuration.isSupported(by: capabilities) {
            return try palette.pair(for: entry.configuration)
        }
        return try palette.pair(for: entry.fallback)
    }
}
