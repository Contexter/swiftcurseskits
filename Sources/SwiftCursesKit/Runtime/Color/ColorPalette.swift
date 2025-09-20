import Foundation

/// Manages ncurses color pair allocation with automatic capability fallbacks.
public struct ColorPalette: Sendable {
    private let runtime: TerminalRuntimeCoordinator

    internal init(runtime: TerminalRuntimeCoordinator) {
        self.runtime = runtime
    }

    /// The capabilities that were detected for the active terminal session.
    public var capabilities: TerminalCapabilities {
        runtime.capabilitiesSnapshot()
    }

    /// Resolves the provided configuration to a color pair identifier.
    /// - Parameter configuration: The desired foreground and background colors.
    /// - Returns: The configured color pair, or ``ColorPair.default`` when colors are unavailable.
    public func pair(for configuration: ColorPairConfiguration) throws -> ColorPair {
        try runtime.colorPair(for: configuration)
    }
}
