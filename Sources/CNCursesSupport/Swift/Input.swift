import CNCursesSupportShims

package enum CNCursesInputAPI {
    package static func readCharacter(from descriptor: CNCursesWindowDescriptor) -> Int32 {
        cncurses_wgetch(descriptor.rawValue)
    }

    package static func setNonBlocking(_ descriptor: CNCursesWindowDescriptor, enabled: Bool) throws
    {
        try CNCursesCall.check(
            result: cncurses_nodelay(descriptor.rawValue, enabled), name: "nodelay")
    }

    package static var noInputCode: Int32 {
        cncurses_error()
    }
}
