/// Represents high-level events delivered to a ``TerminalApp``.
public enum Event: Sendable {
    case tick
    case key(KeyEvent)
}

/// Enumerates keyboard-oriented input events.
public enum KeyEvent: Sendable {
    case character(Character)
}
