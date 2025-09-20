import CNCursesSupport
import Foundation
import _Concurrency

/// Coordinates application execution across the ncurses runtime.
final class TerminalRuntimeCoordinator: @unchecked Sendable {
    static let shared = TerminalRuntimeCoordinator()

    private let lock = NSLock()
    private var isRunning = false
    private var shouldStop = false
    private var screenHandle: WindowHandle?
    private var capabilitiesValue = TerminalCapabilities.headless
    private let colorRegistry = ColorPairRegistry()

    private init() {}

    func run<App: TerminalApp>(app: App) async throws {
        var application = app
        let handle = try start()
        let screen = TerminalScreen(rootHandle: handle)
        let context = AppContext(runtime: self, screen: screen)
        var capturedError: Error?
        let renderer = SceneRenderer()

        do {
            while shouldContinueRunning() {
                try renderer.render(scene: application.body, on: screen)
                if !shouldContinueRunning() {
                    break
                }
                await application.onEvent(.tick, context: context)
                if !shouldContinueRunning() {
                    break
                }
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        } catch {
            capturedError = error
        }

        do {
            try stop()
        } catch {
            if capturedError == nil {
                capturedError = error
            }
        }

        if let capturedError {
            throw capturedError
        }
    }

    func requestShutdown() {
        lock.withLock { shouldStop = true }
    }

    private func shouldContinueRunning() -> Bool {
        lock.withLock { !shouldStop }
    }

    private func start() throws -> WindowHandle {
        var detectedCapabilities = TerminalCapabilities.headless
        let handle = try lock.withLock {
            if isRunning {
                throw TerminalRuntimeError.alreadyRunning
            }
            do {
                _ = try CNCursesRuntime.bootstrap()
            } catch let error as CNCursesRuntimeError {
                if case let .callFailed(name: name, code: code) = error {
                    throw TerminalRuntimeError.ncursesCallFailed(
                        function: name.runtimeFunctionName, code: code)
                }
                throw TerminalRuntimeError.bootstrapFailed
            } catch {
                throw TerminalRuntimeError.bootstrapFailed
            }
            if CNCursesRuntime.isHeadless {
                let handle = WindowHandle(descriptor: nil, ownsLifecycle: false)
                screenHandle = handle
                shouldStop = false
                isRunning = true
                capabilitiesValue = .headless
                detectedCapabilities = .headless
                return handle
            }
            let descriptor: CNCursesWindowDescriptor
            do {
                descriptor = try CNCursesWindowAPI.standardScreen()
            } catch {
                try? CNCursesRuntime.shutdown()
                throw TerminalRuntimeError.bootstrapFailed
            }
            let handle = WindowHandle(descriptor: descriptor, ownsLifecycle: false)
            screenHandle = handle
            shouldStop = false
            isRunning = true
            let capabilities = TerminalCapabilitiesInspector.inspect()
            capabilitiesValue = capabilities
            detectedCapabilities = capabilities
            return handle
        }
        colorRegistry.updateCapabilities(detectedCapabilities)
        return handle
    }

    private func stop() throws {
        let handle: WindowHandle? = lock.withLock {
            defer {
                screenHandle = nil
                shouldStop = false
                isRunning = false
                capabilitiesValue = .headless
            }
            return screenHandle
        }
        handle?.markClosed()
        do {
            try CNCursesRuntime.shutdown()
        } catch let error as CNCursesRuntimeError {
            if case let .callFailed(name: name, code: code) = error {
                throw TerminalRuntimeError.ncursesCallFailed(
                    function: name.runtimeFunctionName, code: code)
            }
            throw TerminalRuntimeError.bootstrapFailed
        } catch {
            throw TerminalRuntimeError.bootstrapFailed
        }
        colorRegistry.reset()
    }

    func capabilitiesSnapshot() -> TerminalCapabilities {
        lock.withLock { capabilitiesValue }
    }

    var palette: ColorPalette { ColorPalette(runtime: self) }

    func colorPair(for configuration: ColorPairConfiguration) throws -> ColorPair {
        try colorRegistry.pair(for: configuration)
    }

    func setMouseCapture(options: MouseCaptureOptions) throws {
        let state = lock.withLock { () -> (active: Bool, capabilities: TerminalCapabilities) in
            (isRunning, capabilitiesValue)
        }
        guard state.active else {
            throw MouseCaptureError.runtimeInactive
        }
        let capabilities = state.capabilities
        if options.isEmpty {
            guard capabilities.supportsMouse else { return }
        } else {
            guard capabilities.supportsMouse else { throw MouseCaptureError.unsupported }
        }
        do {
            try CNCursesMouseAPI.setMouseMask(options.rawValue)
        } catch let error as CNCursesRuntimeError {
            if case let .callFailed(name: _, code: code) = error {
                throw MouseCaptureError.ncursesCallFailed(code: code)
            }
            throw MouseCaptureError.ncursesCallFailed(code: -1)
        } catch {
            throw MouseCaptureError.ncursesCallFailed(code: -1)
        }
    }
}
