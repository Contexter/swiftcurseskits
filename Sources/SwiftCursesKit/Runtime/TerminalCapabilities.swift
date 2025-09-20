import CNCursesSupport
import Foundation

/// Represents the runtime capabilities detected for the attached terminal.
public struct TerminalCapabilities: Sendable, Equatable {
    /// Indicates whether the runtime is operating without a terminal.
    public var isHeadless: Bool
    /// Indicates whether color rendering is available.
    public var supportsColor: Bool
    /// The number of distinct colors reported by the terminal.
    public var colorCount: Int
    /// The number of color pairs supported by the terminal runtime.
    public var colorPairCount: Int
    /// Indicates whether the terminal honors the `-1` default color sentinel.
    public var supportsDefaultColors: Bool
    /// Indicates whether the terminal allows runtime color reconfiguration.
    public var supportsDynamicColorChanges: Bool
    /// Indicates whether mouse input is available.
    public var supportsMouse: Bool

    /// Creates a custom capabilities description.
    /// - Parameters:
    ///   - isHeadless: Indicates whether the runtime is headless.
    ///   - supportsColor: Indicates whether color rendering is available.
    ///   - colorCount: The maximum number of colors supported.
    ///   - colorPairCount: The maximum number of color pairs supported.
    ///   - supportsDefaultColors: Indicates whether the terminal supports default colors.
    ///   - supportsDynamicColorChanges: Indicates dynamic color support.
    ///   - supportsMouse: Indicates whether mouse input is supported.
    public init(
        isHeadless: Bool,
        supportsColor: Bool,
        colorCount: Int,
        colorPairCount: Int,
        supportsDefaultColors: Bool,
        supportsDynamicColorChanges: Bool,
        supportsMouse: Bool
    ) {
        self.isHeadless = isHeadless
        self.supportsColor = supportsColor
        self.colorCount = colorCount
        self.colorPairCount = colorPairCount
        self.supportsDefaultColors = supportsDefaultColors
        self.supportsDynamicColorChanges = supportsDynamicColorChanges
        self.supportsMouse = supportsMouse
    }

    /// A capabilities description for headless execution.
    public static var headless: TerminalCapabilities {
        TerminalCapabilities(
            isHeadless: true,
            supportsColor: false,
            colorCount: 0,
            colorPairCount: 0,
            supportsDefaultColors: false,
            supportsDynamicColorChanges: false,
            supportsMouse: false
        )
    }
}

enum TerminalCapabilitiesInspector {
    static func inspect() -> TerminalCapabilities {
        let environment = CNCursesBridge.environment
        guard environment.runtime.isHeadless() == false else {
            return .headless
        }

        var supportsColor = false
        var colorCount = 0
        var colorPairCount = 0
        var supportsDefaultColors = false
        var supportsDynamicColorChanges = false

        if environment.color.hasColorSupport() {
            do {
                try environment.color.startColor()
                supportsColor = true
                colorCount = max(environment.color.colorCount(), 0)
                colorPairCount = max(environment.color.colorPairCount(), 0)
                supportsDefaultColors = environment.color.enableDefaultColors()
                supportsDynamicColorChanges = environment.color.canChangeColor()
            } catch {
                supportsColor = false
                colorCount = 0
                colorPairCount = 0
                supportsDefaultColors = false
                supportsDynamicColorChanges = false
            }
        }

        let supportsMouse = environment.mouse.hasMouseSupport() && !environment.runtime.isHeadless()

        return TerminalCapabilities(
            isHeadless: false,
            supportsColor: supportsColor,
            colorCount: colorCount,
            colorPairCount: colorPairCount,
            supportsDefaultColors: supportsDefaultColors,
            supportsDynamicColorChanges: supportsDynamicColorChanges,
            supportsMouse: supportsMouse
        )
    }
}
