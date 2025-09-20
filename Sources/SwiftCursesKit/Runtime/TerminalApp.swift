import Foundation

/// Describes the entry point for an ncurses powered terminal experience.
///
/// A ``TerminalApp`` defines the declarative scene that should be rendered on
/// every pass of the runtime loop and optionally reacts to incoming events.
/// Conforming types declare their user interface through a ``SceneBuilder``
/// composition and rely on ``SceneRenderer`` to translate the layout tree into
/// ncurses draw commands.
public protocol TerminalApp: Sendable {
    /// The type of scene produced by the application.
    associatedtype Body: Scene

    /// The textual banner presented when the application launches.
    var banner: String { get }

    /// The root scene describing the application's interface.
    @SceneBuilder var body: Body { get }

    /// Invoked by the runtime when a new event is available.
    ///
    /// Conforming applications should update their state in response to the
    /// provided ``Event`` and invoke ``AppContext.quit()`` when the app should
    /// terminate.
    mutating func onEvent(_ event: Event, context: AppContext) async
}

public extension TerminalApp {
    /// Provides a default banner for applications that do not specify one.
    var banner: String { "SwiftCursesKit" }

    /// Default no-op event handler.
    mutating func onEvent(_ event: Event, context: AppContext) async {}

    /// Boots the terminal runtime and executes the main loop.
    /// - Returns: The banner text that callers can display to a user.
    /// - Throws: ``TerminalRuntimeError`` when the runtime cannot be started or
    ///   shut down cleanly.
    @discardableResult
    func run() async throws -> String {
        try await TerminalRuntimeCoordinator.shared.run(app: self)
        return banner
    }
}
