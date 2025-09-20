import CNCursesSupport
import Foundation

/// An asynchronous stream of terminal ``Event`` values.
public struct EventStream: AsyncSequence, Sendable {
  public typealias Element = Event

  private let stream: AsyncStream<Event>

  internal init(stream: AsyncStream<Event>) {
    self.stream = stream
  }

  public struct AsyncIterator: AsyncIteratorProtocol {
    private var iterator: AsyncStream<Event>.AsyncIterator

    fileprivate init(iterator: AsyncStream<Event>.AsyncIterator) {
      self.iterator = iterator
    }

    public mutating func next() async -> Event? {
      await iterator.next()
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(iterator: stream.makeAsyncIterator())
  }
}

/// Coordinates event delivery from ncurses into ``Event`` values.
final class TerminalEventSource: @unchecked Sendable {
  private let windowHandle: WindowHandle
  private let shouldContinue: @Sendable () -> Bool
  private let clock = ContinuousClock()
  private let lock = NSLock()

  private let stream: AsyncStream<Event>
  private var continuation: AsyncStream<Event>.Continuation?
  private var pollTask: Task<Void, Never>?
  private var ancillaryTasks: [UUID: Task<Void, Never>] = [:]
  private var tickSequence: UInt64 = 0
  private var isStopped = false

  internal init(windowHandle: WindowHandle, shouldContinue: @escaping @Sendable () -> Bool) {
    self.windowHandle = windowHandle
    self.shouldContinue = shouldContinue
    let pair = AsyncStream<Event>.makeStream(of: Event.self)
    self.stream = pair.stream
    lock.withLock {
      continuation = pair.continuation
    }
    pair.continuation.onTermination = {
      [weak self] (_: AsyncStream<Event>.Continuation.Termination) in
      self?.stop()
    }
  }

  func events() -> EventStream {
    EventStream(stream: stream)
  }

  func start() {
    lock.lock()
    if pollTask != nil || isStopped {
      lock.unlock()
      return
    }
    lock.unlock()

    let task = Task<Void, Never> { [weak self] in
      guard let self else { return }
      await self.pollLoop()
    }

    lock.withLock {
      if isStopped {
        task.cancel()
      } else {
        pollTask = task
      }
    }
  }

  func stop() {
    let (tasks, continuation) = lock.withLock {
      () -> ([Task<Void, Never>], AsyncStream<Event>.Continuation?) in
      if isStopped {
        return ([], nil)
      }
      isStopped = true
      let poll = pollTask
      pollTask = nil
      let ancillary = Array(ancillaryTasks.values)
      ancillaryTasks.removeAll()
      let continuation = self.continuation
      self.continuation = nil
      var tasks: [Task<Void, Never>] = ancillary
      if let poll {
        tasks.append(poll)
      }
      return (tasks, continuation)
    }
    continuation?.finish()
    for task in tasks {
      task.cancel()
    }
  }

  @discardableResult
  func scheduleTicks(every interval: Duration, immediate: Bool) -> Task<Void, Never> {
    let token = UUID()
    let task = Task { [weak self] in
      guard let self else { return }
      defer { self.unregisterAuxiliaryTask(token) }
      guard !Task.isCancelled, self.shouldContinue() else { return }
      if immediate {
        self.emitTick(interval: interval)
      }
      while !Task.isCancelled, self.shouldContinue() {
        do {
          try await Task.sleep(for: interval)
        } catch {
          break
        }
        if Task.isCancelled || !self.shouldContinue() {
          break
        }
        self.emitTick(interval: interval)
      }
    }
    registerAuxiliaryTask(task, token: token)
    return task
  }

  private func registerAuxiliaryTask(_ task: Task<Void, Never>, token: UUID) {
    lock.withLock {
      if isStopped {
        task.cancel()
        return
      }
      ancillaryTasks[token] = task
    }
  }

  private func unregisterAuxiliaryTask(_ token: UUID) {
    _ = lock.withLock {
      ancillaryTasks.removeValue(forKey: token)
    }
  }

  private func nextTickSequence() -> UInt64 {
    lock.withLock {
      tickSequence &+= 1
      return tickSequence
    }
  }

  private func emitTick(interval: Duration) {
    let sequence = nextTickSequence()
    emit(.tick(TickEvent(sequence: sequence, interval: interval, timestamp: clock.now)))
  }

  private func emit(_ event: Event) {
    _ = lock.withLock {
      continuation?.yield(event)
    }
  }

  private func pollLoop() async {
    defer { finishStreamIfNeeded() }
    while shouldContinue(), !Task.isCancelled {
      guard let descriptor = windowHandle.withDescriptor({ $0 }) else {
        do {
          try await Task.sleep(for: .milliseconds(25))
        } catch {
          break
        }
        continue
      }

      switch CNCursesInputAPI.readEvent(from: descriptor) {
      case .none:
        do {
          try await Task.sleep(for: .milliseconds(5))
        } catch {
          return
        }
      case let .character(value):
        if let key = KeyEvent(unicodeScalarValue: value) {
          emit(.key(key))
        }
      case let .keyCode(code):
        handleKeyCode(code, descriptor: descriptor)
      }
    }
  }

  private func finishStreamIfNeeded() {
    let continuation = lock.withLock { () -> AsyncStream<Event>.Continuation? in
      let existing = self.continuation
      self.continuation = nil
      return existing
    }
    continuation?.finish()
  }

  private func handleKeyCode(_ code: UInt32, descriptor: CNCursesWindowDescriptor) {
    if code == CNCursesKeyCode.mouse {
      guard let event = CNCursesInputAPI.nextMouseEvent() else { return }
      emit(.mouse(MouseEvent(from: event)))
    } else if code == CNCursesKeyCode.resize {
      let size = CNCursesWindowAPI.size(of: descriptor)
      emit(.terminal(.resized(TerminalSize(rows: size.rows, columns: size.columns))))
    } else {
      emit(.key(KeyEvent(keyCode: code)))
    }
  }
}

extension KeyEvent {
  fileprivate init?(unicodeScalarValue value: UInt32) {
    guard let scalar = UnicodeScalar(value) else { return nil }
    switch scalar.value {
    case 0x09:
      self = KeyEvent(key: .tab)
    case 0x0A, 0x0D:
      self = KeyEvent(key: .enter)
    case 0x1B:
      self = KeyEvent(key: .escape)
    case 0x7F:
      self = KeyEvent(key: .backspace)
    case 0x00...0x1F:
      self = KeyEvent(key: .control(UInt8(scalar.value)))
    default:
      self = KeyEvent(key: .character(Character(scalar)))
    }
  }

  fileprivate init(keyCode: UInt32) {
    if Self.codeIsFunctionKey(keyCode) {
      let base = Int(keyCode - CNCursesKeyCode.function(0))
      let index = base > 0 ? base : 0
      self = KeyEvent(key: .function(index))
      return
    }

    switch keyCode {
    case CNCursesKeyCode.enter:
      self = KeyEvent(key: .enter)
    case CNCursesKeyCode.backspace:
      self = KeyEvent(key: .backspace)
    case CNCursesKeyCode.up:
      self = KeyEvent(key: .arrow(.up))
    case CNCursesKeyCode.down:
      self = KeyEvent(key: .arrow(.down))
    case CNCursesKeyCode.left:
      self = KeyEvent(key: .arrow(.left))
    case CNCursesKeyCode.right:
      self = KeyEvent(key: .arrow(.right))
    case CNCursesKeyCode.home:
      self = KeyEvent(key: .home)
    case CNCursesKeyCode.end:
      self = KeyEvent(key: .end)
    case CNCursesKeyCode.pageUp:
      self = KeyEvent(key: .pageUp)
    case CNCursesKeyCode.pageDown:
      self = KeyEvent(key: .pageDown)
    case CNCursesKeyCode.insert:
      self = KeyEvent(key: .insert)
    case CNCursesKeyCode.delete:
      self = KeyEvent(key: .delete)
    case CNCursesKeyCode.backTab:
      self = KeyEvent(key: .tab, modifiers: [.shift])
    default:
      self = KeyEvent(key: .unknown(code: keyCode))
    }
  }

  private static func codeIsFunctionKey(_ code: UInt32) -> Bool {
    let f1 = CNCursesKeyCode.function(1)
    let f64 = CNCursesKeyCode.function(64)
    return code >= f1 && code <= f64
  }
}

extension MouseEvent {
  fileprivate init(from event: CNCursesMouseEvent) {
    let location = Location(row: Int(event.y), column: Int(event.x))
    let modifiers = MouseEvent.modifiers(for: event.state)
    let action = MouseEvent.action(for: event.state)
    self.init(location: location, action: action, modifiers: modifiers, rawState: event.state)
  }

  private static func modifiers(for state: UInt64) -> Modifiers {
    var modifiers: Modifiers = []
    if state & CNCursesMouseMask.buttonShift != 0 {
      modifiers.insert(.shift)
    }
    if state & CNCursesMouseMask.buttonControl != 0 {
      modifiers.insert(.control)
    }
    if state & CNCursesMouseMask.buttonAlt != 0 {
      modifiers.insert(.alt)
    }
    return modifiers
  }

  private static func action(for state: UInt64) -> Action {
    if let action = action(
      for: state, button: .left, pressed: CNCursesMouseMask.button1Pressed,
      released: CNCursesMouseMask.button1Released, clicked: CNCursesMouseMask.button1Clicked,
      doubleClicked: CNCursesMouseMask.button1DoubleClicked,
      tripleClicked: CNCursesMouseMask.button1TripleClicked)
    {
      return action
    }
    if let action = action(
      for: state, button: .middle, pressed: CNCursesMouseMask.button2Pressed,
      released: CNCursesMouseMask.button2Released, clicked: CNCursesMouseMask.button2Clicked,
      doubleClicked: CNCursesMouseMask.button2DoubleClicked,
      tripleClicked: CNCursesMouseMask.button2TripleClicked)
    {
      return action
    }
    if let action = action(
      for: state, button: .right, pressed: CNCursesMouseMask.button3Pressed,
      released: CNCursesMouseMask.button3Released, clicked: CNCursesMouseMask.button3Clicked,
      doubleClicked: CNCursesMouseMask.button3DoubleClicked,
      tripleClicked: CNCursesMouseMask.button3TripleClicked)
    {
      return action
    }

    if state & CNCursesMouseMask.button4Pressed != 0 {
      return .scrolled(vertical: 1, horizontal: 0)
    }
    if state & CNCursesMouseMask.button5Pressed != 0 {
      return .scrolled(vertical: -1, horizontal: 0)
    }
    if CNCursesMouseMask.button6Pressed != 0 && state & CNCursesMouseMask.button6Pressed != 0 {
      return .scrolled(vertical: 0, horizontal: 1)
    }
    if CNCursesMouseMask.button7Pressed != 0 && state & CNCursesMouseMask.button7Pressed != 0 {
      return .scrolled(vertical: 0, horizontal: -1)
    }

    if state & CNCursesMouseMask.reportPosition != 0 {
      if state & CNCursesMouseMask.button1Pressed != 0 {
        return .dragged(.left)
      }
      if state & CNCursesMouseMask.button2Pressed != 0 {
        return .dragged(.middle)
      }
      if state & CNCursesMouseMask.button3Pressed != 0 {
        return .dragged(.right)
      }
      return .moved
    }

    return .unknown(rawState: state)
  }

  private static func action(
    for state: UInt64,
    button: Button,
    pressed: UInt64,
    released: UInt64,
    clicked: UInt64,
    doubleClicked: UInt64,
    tripleClicked: UInt64
  ) -> Action? {
    if state & pressed != 0 {
      return .pressed(button)
    }
    if state & released != 0 {
      return .released(button)
    }
    if state & tripleClicked != 0 {
      return .clicked(button, count: 3)
    }
    if state & doubleClicked != 0 {
      return .clicked(button, count: 2)
    }
    if state & clicked != 0 {
      return .clicked(button, count: 1)
    }
    return nil
  }
}
