import CNCursesSupport
import Foundation

/// Bridges a raw ncurses window pointer into a Swift managed object.
final class WindowHandle: @unchecked Sendable {
    private let descriptor: CNCursesWindowDescriptor?
    private let ownsLifecycle: Bool
    private var closed = false
    private let lock = NSLock()

    init(descriptor: CNCursesWindowDescriptor?, ownsLifecycle: Bool) {
        self.descriptor = descriptor
        self.ownsLifecycle = ownsLifecycle
    }

    var isClosed: Bool {
        lock.withLock { closed }
    }

    func close() throws {
        try lock.withLock {
            guard !closed else { return }
            if ownsLifecycle, let descriptor {
                do {
                    try CNCursesWindowAPI.destroyWindow(descriptor)
                } catch let error as CNCursesRuntimeError {
                    if case let .callFailed(name: name, code: code) = error {
                        throw TerminalRuntimeError.ncursesCallFailed(
                            function: name.runtimeFunctionName, code: code)
                    }
                    throw TerminalRuntimeError.bootstrapFailed
                } catch {
                    throw TerminalRuntimeError.bootstrapFailed
                }
            }
            closed = true
        }
    }

    func closeSilently() {
        do {
            try close()
        } catch {
            // Runtime teardown must never throw during ARC cleanup.
        }
    }

    func markClosed() {
        lock.withLock { closed = true }
    }

    func withDescriptor<T>(_ body: (CNCursesWindowDescriptor) throws -> T) rethrows -> T? {
        let descriptor = lock.withLock { self.descriptor }
        guard let descriptor else {
            return nil
        }
        return try body(descriptor)
    }
}
