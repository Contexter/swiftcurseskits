@_implementationOnly import CNCursesSupportShims

package enum CNCursesInputAPI {
  package enum ReadResult: Equatable {
    case none
    case character(UInt32)
    case keyCode(UInt32)
  }

  package static func readEvent(from descriptor: CNCursesWindowDescriptor) -> ReadResult {
    var value: UInt32 = 0
    let result = cncurses_wget_wch(descriptor.rawValue, &value)
    if result == cncurses_error() {
      return .none
    }
    if UInt32(result) == CNCursesKeyCode.codeYes {
      return .keyCode(value)
    }
    return .character(value)
  }

  package static func enableNonBlockingInput(for descriptor: CNCursesWindowDescriptor) throws {
    try CNCursesCall.check(result: cncurses_nodelay(descriptor.rawValue, true), name: "nodelay")
  }

  package static func enableMouseReporting() {
    guard cncurses_has_mouse() else { return }
    _ = cncurses_mousemask(
      cncurses_all_mouse_events() | cncurses_report_mouse_position(),
      nil
    )
  }

  package static func nextMouseEvent() -> CNCursesMouseEvent? {
    var raw = CNCursesSupportShims.CNCursesMouseEvent(identifier: 0, x: 0, y: 0, z: 0, state: 0)
    let result = withUnsafeMutablePointer(to: &raw) { pointer in
      cncurses_getmouse(pointer)
    }
    if result == cncurses_error() {
      return nil
    }
    return CNCursesMouseEvent(
      identifier: raw.identifier,
      x: raw.x,
      y: raw.y,
      z: raw.z,
      state: raw.state
    )
  }
}

package enum CNCursesKeyCode {
  package static let codeYes: UInt32 = cncurses_key_code_yes()
  package static let mouse: UInt32 = cncurses_key_mouse()
  package static let resize: UInt32 = cncurses_key_resize()
  package static let enter: UInt32 = cncurses_key_enter()
  package static let backspace: UInt32 = cncurses_key_backspace()
  package static let up: UInt32 = cncurses_key_up()
  package static let down: UInt32 = cncurses_key_down()
  package static let left: UInt32 = cncurses_key_left()
  package static let right: UInt32 = cncurses_key_right()
  package static let home: UInt32 = cncurses_key_home()
  package static let end: UInt32 = cncurses_key_end()
  package static let pageDown: UInt32 = cncurses_key_npage()
  package static let pageUp: UInt32 = cncurses_key_ppage()
  package static let insert: UInt32 = cncurses_key_ic()
  package static let delete: UInt32 = cncurses_key_dc()
  package static let backTab: UInt32 = cncurses_key_btab()

  package static func function(_ index: Int) -> UInt32 {
    cncurses_key_f(Int32(index))
  }
}

package struct CNCursesMouseEvent: Sendable {
  package let identifier: Int16
  package let x: Int32
  package let y: Int32
  package let z: Int32
  package let state: UInt64
}

package enum CNCursesMouseMask {
  package static let reportPosition: UInt64 = cncurses_report_mouse_position()
  package static let buttonShift: UInt64 = cncurses_button_shift()
  package static let buttonControl: UInt64 = cncurses_button_ctrl()
  package static let buttonAlt: UInt64 = cncurses_button_alt()

  package static let button1Pressed: UInt64 = cncurses_button1_pressed()
  package static let button1Released: UInt64 = cncurses_button1_released()
  package static let button1Clicked: UInt64 = cncurses_button1_clicked()
  package static let button1DoubleClicked: UInt64 = cncurses_button1_double_clicked()
  package static let button1TripleClicked: UInt64 = cncurses_button1_triple_clicked()

  package static let button2Pressed: UInt64 = cncurses_button2_pressed()
  package static let button2Released: UInt64 = cncurses_button2_released()
  package static let button2Clicked: UInt64 = cncurses_button2_clicked()
  package static let button2DoubleClicked: UInt64 = cncurses_button2_double_clicked()
  package static let button2TripleClicked: UInt64 = cncurses_button2_triple_clicked()

  package static let button3Pressed: UInt64 = cncurses_button3_pressed()
  package static let button3Released: UInt64 = cncurses_button3_released()
  package static let button3Clicked: UInt64 = cncurses_button3_clicked()
  package static let button3DoubleClicked: UInt64 = cncurses_button3_double_clicked()
  package static let button3TripleClicked: UInt64 = cncurses_button3_triple_clicked()

  package static let button4Pressed: UInt64 = cncurses_button4_pressed()
  package static let button5Pressed: UInt64 = cncurses_button5_pressed()
  package static let button6Pressed: UInt64 = cncurses_button6_pressed()
  package static let button7Pressed: UInt64 = cncurses_button7_pressed()
}
