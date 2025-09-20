import Foundation

/// Represents high-level events delivered to a ``TerminalApp``.
public enum Event: Sendable, Equatable {
  /// A scheduled timer or animation event.
  case tick(TickEvent)
  /// A keyboard input event.
  case key(KeyEvent)
  /// A mouse input event.
  case mouse(MouseEvent)
  /// A terminal lifecycle or environmental change event.
  case terminal(TerminalEvent)
}

/// Describes a scheduled timer callback delivered through ``Event.tick(_:)``.
public struct TickEvent: Sendable, Equatable {
  /// A monotonically increasing identifier assigned to each tick.
  public let sequence: UInt64
  /// The intended cadence between ticks.
  public let interval: Duration
  /// The time at which the tick was emitted.
  public let timestamp: ContinuousClock.Instant

  /// Creates a new tick representation.
  /// - Parameters:
  ///   - sequence: The monotonically increasing sequence number for this tick.
  ///   - interval: The cadence between successive ticks.
  ///   - timestamp: The moment at which the tick was generated.
  public init(sequence: UInt64, interval: Duration, timestamp: ContinuousClock.Instant? = nil) {
    self.sequence = sequence
    self.interval = interval
    self.timestamp = timestamp ?? ContinuousClock().now
  }
}

/// Enumerates keyboard-oriented input events.
public struct KeyEvent: Sendable, Equatable {
  /// Bitset describing key modifiers active during the event.
  public struct Modifiers: OptionSet, Sendable {
    public let rawValue: UInt8

    /// Indicates that the Shift key was active.
    public static let shift = Modifiers(rawValue: 1 << 0)
    /// Indicates that the Control key was active.
    public static let control = Modifiers(rawValue: 1 << 1)
    /// Indicates that the Alt/Option key was active.
    public static let alt = Modifiers(rawValue: 1 << 2)

    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
  }

  /// Represents the semantic meaning of a key event.
  public enum Key: Sendable, Equatable {
    /// A printable character, including extended Unicode scalars.
    case character(Character)
    /// An ASCII control character (for example `^C`).
    case control(UInt8)
    /// The Enter or Return key.
    case enter
    /// The Tab key.
    case tab
    /// The Escape key.
    case escape
    /// The Backspace key.
    case backspace
    /// Arrow key input.
    case arrow(Direction)
    /// Navigational Home key.
    case home
    /// Navigational End key.
    case end
    /// Page up navigation key.
    case pageUp
    /// Page down navigation key.
    case pageDown
    /// Insert key.
    case insert
    /// Delete key.
    case delete
    /// Function key with the supplied index (starting at 1).
    case function(Int)
    /// A key that is not yet mapped to a semantic representation.
    case unknown(code: UInt32)
  }

  /// Directional arrows produced by arrow keys.
  public enum Direction: Sendable, Equatable {
    case up
    case down
    case left
    case right
  }

  /// The semantic key that was activated.
  public let key: Key

  /// The modifier flags active for this event.
  public let modifiers: Modifiers

  /// Creates a key event with the supplied semantics and modifiers.
  /// - Parameters:
  ///   - key: The semantic key representation.
  ///   - modifiers: Active modifier flags. Defaults to none.
  public init(key: Key, modifiers: Modifiers = []) {
    self.key = key
    self.modifiers = modifiers
  }
}

/// Represents a pointer interaction received from ncurses.
public struct MouseEvent: Sendable, Equatable {
  /// The position in the terminal grid where the event occurred.
  public struct Location: Sendable, Equatable {
    public var row: Int
    public var column: Int

    public init(row: Int, column: Int) {
      self.row = row
      self.column = column
    }
  }

  /// Indicates which button triggered the event.
  public enum Button: Sendable, Equatable {
    case left
    case middle
    case right
    case other(Int)
  }

  /// Describes the action performed by the mouse input.
  public enum Action: Sendable, Equatable {
    case pressed(Button)
    case released(Button)
    case clicked(Button, count: Int)
    case dragged(Button)
    case scrolled(vertical: Int, horizontal: Int)
    case moved
    case unknown(rawState: UInt64)
  }

  /// Modifiers active during the mouse event.
  public struct Modifiers: OptionSet, Sendable {
    public let rawValue: UInt8

    public static let shift = Modifiers(rawValue: 1 << 0)
    public static let control = Modifiers(rawValue: 1 << 1)
    public static let alt = Modifiers(rawValue: 1 << 2)

    public init(rawValue: UInt8) {
      self.rawValue = rawValue
    }
  }

  /// The location of the pointer interaction.
  public let location: Location
  /// The resolved action associated with the raw mouse state.
  public let action: Action
  /// Modifier keys active during the event.
  public let modifiers: Modifiers
  /// The raw bitset reported by ncurses for additional processing.
  public let rawState: UInt64

  /// Creates a new mouse event description.
  /// - Parameters:
  ///   - location: Terminal coordinates associated with the event.
  ///   - action: The resolved mouse action.
  ///   - modifiers: Active modifier flags.
  ///   - rawState: The raw ncurses bitset for the event.
  public init(location: Location, action: Action, modifiers: Modifiers = [], rawState: UInt64) {
    self.location = location
    self.action = action
    self.modifiers = modifiers
    self.rawState = rawState
  }
}

/// Events that describe terminal lifecycle changes.
public enum TerminalEvent: Sendable, Equatable {
  case resized(TerminalSize)
}

/// Represents the current terminal grid dimensions.
public struct TerminalSize: Sendable, Equatable {
  public var rows: Int
  public var columns: Int

  public init(rows: Int, columns: Int) {
    self.rows = rows
    self.columns = columns
  }
}
