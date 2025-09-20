import CNCursesSupportShims
import Foundation

package struct CNCursesWindowDescriptor: @unchecked Sendable {
    let rawValue: UnsafeMutableRawPointer
}

package enum CNCursesWindowAPI {
    package static func standardScreen() throws -> CNCursesWindowDescriptor {
        guard let pointer = cncurses_stdscr() else {
            throw CNCursesRuntimeError.initializationFailed
        }
        return CNCursesWindowDescriptor(rawValue: pointer)
    }

    package static func destroyWindow(_ descriptor: CNCursesWindowDescriptor) throws {
        try CNCursesCall.check(result: cncurses_delwin(descriptor.rawValue), name: "delwin")
    }

    package static func size(of descriptor: CNCursesWindowDescriptor) -> (rows: Int, columns: Int) {
        var rows: Int32 = 0
        var columns: Int32 = 0
        cncurses_getmaxyx(descriptor.rawValue, &rows, &columns)
        return (Int(rows), Int(columns))
    }

    package static func clear(_ descriptor: CNCursesWindowDescriptor) throws {
        try CNCursesCall.check(result: cncurses_wclear(descriptor.rawValue), name: "wclear")
    }

    package static func draw(
        _ string: String, descriptor: CNCursesWindowDescriptor, y: Int, x: Int
    ) throws {
        try string.withCString { pointer in
            try CNCursesCall.check(
                result: cncurses_mvwaddnstr(
                    descriptor.rawValue, Int32(y), Int32(x), pointer, Int32(string.count)),
                name: "mvwaddnstr")
        }
    }

    package static func stage(_ descriptor: CNCursesWindowDescriptor) throws {
        try CNCursesCall.check(
            result: cncurses_wnoutrefresh(descriptor.rawValue), name: "wnoutrefresh")
    }

    package static func commitStagedUpdates() throws {
        try CNCursesCall.check(result: cncurses_doupdate(), name: "doupdate")
    }
}
