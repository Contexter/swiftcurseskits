import CNCursesSupportShims
import Foundation

package enum CNCursesColorAPI {
    package static var hasColorSupport: Bool {
        cncurses_has_colors()
    }

    package static func startColor() throws {
        try CNCursesCall.check(result: cncurses_start_color(), name: "start_color")
    }

    package static func enableDefaultColors() -> Bool {
        cncurses_use_default_colors() != cncurses_error()
    }

    package static func colorCount() -> Int {
        Int(cncurses_color_count())
    }

    package static func colorPairCount() -> Int {
        Int(cncurses_color_pair_count())
    }

    package static func canChangeColor() -> Bool {
        cncurses_can_change_color()
    }

    package static func initializePair(identifier: Int16, foreground: Int16, background: Int16)
        throws
    {
        try CNCursesCall.check(
            result: cncurses_init_pair(identifier, foreground, background),
            name: "init_pair"
        )
    }

    package static func blackIdentifier() -> Int16 { cncurses_color_black() }

    package static func redIdentifier() -> Int16 { cncurses_color_red() }

    package static func greenIdentifier() -> Int16 { cncurses_color_green() }

    package static func yellowIdentifier() -> Int16 { cncurses_color_yellow() }

    package static func blueIdentifier() -> Int16 { cncurses_color_blue() }

    package static func magentaIdentifier() -> Int16 { cncurses_color_magenta() }

    package static func cyanIdentifier() -> Int16 { cncurses_color_cyan() }

    package static func whiteIdentifier() -> Int16 { cncurses_color_white() }
}

package enum CNCursesMouseAPI {
    package static var hasMouseSupport: Bool {
        cncurses_has_mouse()
    }

    package static func setMouseMask(_ mask: UInt) throws {
        try CNCursesCall.check(result: cncurses_set_mousemask(mask), name: "mousemask")
    }

    package static func allEventsMask() -> UInt {
        UInt(cncurses_all_mouse_events())
    }

    package static func reportPositionMask() -> UInt {
        UInt(cncurses_report_mouse_position())
    }
}
