import Foundation

/// Describes the foreground and background colors that should be assigned to a color pair.
public struct ColorPairConfiguration: Sendable, Hashable {
    /// The desired foreground color, or `nil` to use the terminal default.
    public var foreground: TerminalColor?
    /// The desired background color, or `nil` to use the terminal default.
    public var background: TerminalColor?

    /// Creates a configuration with the provided colors.
    /// - Parameters:
    ///   - foreground: The foreground color, or `nil` for the default.
    ///   - background: The background color, or `nil` for the default.
    public init(foreground: TerminalColor? = nil, background: TerminalColor? = nil) {
        self.foreground = foreground
        self.background = background
    }

    /// A configuration that preserves the terminal defaults.
    public static var monochrome: ColorPairConfiguration { ColorPairConfiguration() }

    var isDefault: Bool { foreground == nil && background == nil }

    var requiresDefaultColors: Bool { foreground == nil || background == nil }

    func isSupported(by capabilities: TerminalCapabilities) -> Bool {
        guard capabilities.supportsColor else {
            return false
        }
        if requiresDefaultColors && !capabilities.supportsDefaultColors {
            return false
        }
        if let foreground, !foreground.isSupported(by: capabilities) {
            return false
        }
        if let background, !background.isSupported(by: capabilities) {
            return false
        }
        return true
    }

    func resolvedComponents(for capabilities: TerminalCapabilities) -> (Int16, Int16) {
        let defaultSentinel: Int16 = -1
        let foregroundValue = foreground?.rawValue ?? defaultSentinel
        let backgroundValue = background?.rawValue ?? defaultSentinel
        return (foregroundValue, backgroundValue)
    }
}
