@_implementationOnly import CNCursesSupportShims
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
}
