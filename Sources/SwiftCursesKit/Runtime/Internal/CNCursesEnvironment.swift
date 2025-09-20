import CNCursesSupport
import Foundation

struct CNCursesEnvironment {
    struct Runtime {
        var bootstrap: @Sendable () throws -> Bool
        var shutdown: @Sendable () throws -> Void
        var isHeadless: @Sendable () -> Bool
    }

    struct Window {
        var standardScreen: @Sendable () throws -> CNCursesWindowDescriptor
        var destroyWindow: @Sendable (CNCursesWindowDescriptor) throws -> Void
        var size: @Sendable (CNCursesWindowDescriptor) -> (rows: Int, columns: Int)
        var clear: @Sendable (CNCursesWindowDescriptor) throws -> Void
        var draw: @Sendable (String, CNCursesWindowDescriptor, Int, Int) throws -> Void
        var stage: @Sendable (CNCursesWindowDescriptor) throws -> Void
        var commit: @Sendable () throws -> Void
    }

    struct Input {
        var readCharacter: @Sendable (CNCursesWindowDescriptor) -> Int32
        var noInputCode: @Sendable () -> Int32
    }

    struct Color {
        var hasColorSupport: @Sendable () -> Bool
        var startColor: @Sendable () throws -> Void
        var colorCount: @Sendable () -> Int
        var colorPairCount: @Sendable () -> Int
        var enableDefaultColors: @Sendable () -> Bool
        var canChangeColor: @Sendable () -> Bool
        var initializePair: @Sendable (Int16, Int16, Int16) throws -> Void
        var blackIdentifier: @Sendable () -> Int16
        var redIdentifier: @Sendable () -> Int16
        var greenIdentifier: @Sendable () -> Int16
        var yellowIdentifier: @Sendable () -> Int16
        var blueIdentifier: @Sendable () -> Int16
        var magentaIdentifier: @Sendable () -> Int16
        var cyanIdentifier: @Sendable () -> Int16
        var whiteIdentifier: @Sendable () -> Int16
    }

    struct Mouse {
        var hasMouseSupport: @Sendable () -> Bool
        var setMouseMask: @Sendable (UInt) throws -> Void
        var allEventsMask: @Sendable () -> UInt
        var reportPositionMask: @Sendable () -> UInt
    }

    var runtime: Runtime
    var window: Window
    var input: Input
    var color: Color
    var mouse: Mouse
}

enum CNCursesBridge {
    private static let storage = LockedValue(CNCursesEnvironment.live)

    static var environment: CNCursesEnvironment {
        get { storage.withValue { $0 } }
        set { storage.withValue { $0 = newValue } }
    }
}

extension CNCursesEnvironment {
    static var live: CNCursesEnvironment {
        CNCursesEnvironment(
            runtime: .init(
                bootstrap: { try CNCursesRuntime.bootstrap() },
                shutdown: { try CNCursesRuntime.shutdown() },
                isHeadless: { CNCursesRuntime.isHeadless }
            ),
            window: .init(
                standardScreen: { try CNCursesWindowAPI.standardScreen() },
                destroyWindow: { try CNCursesWindowAPI.destroyWindow($0) },
                size: { CNCursesWindowAPI.size(of: $0) },
                clear: { try CNCursesWindowAPI.clear($0) },
                draw: { text, descriptor, y, x in
                    try CNCursesWindowAPI.draw(text, descriptor: descriptor, y: y, x: x)
                },
                stage: { try CNCursesWindowAPI.stage($0) },
                commit: { try CNCursesWindowAPI.commitStagedUpdates() }
            ),
            input: .init(
                readCharacter: { CNCursesInputAPI.readCharacter(from: $0) },
                noInputCode: { CNCursesInputAPI.noInputCode }
            ),
            color: .init(
                hasColorSupport: { CNCursesColorAPI.hasColorSupport },
                startColor: { try CNCursesColorAPI.startColor() },
                colorCount: { CNCursesColorAPI.colorCount() },
                colorPairCount: { CNCursesColorAPI.colorPairCount() },
                enableDefaultColors: { CNCursesColorAPI.enableDefaultColors() },
                canChangeColor: { CNCursesColorAPI.canChangeColor() },
                initializePair: { identifier, foreground, background in
                    try CNCursesColorAPI.initializePair(
                        identifier: identifier, foreground: foreground, background: background)
                },
                blackIdentifier: { CNCursesColorAPI.blackIdentifier() },
                redIdentifier: { CNCursesColorAPI.redIdentifier() },
                greenIdentifier: { CNCursesColorAPI.greenIdentifier() },
                yellowIdentifier: { CNCursesColorAPI.yellowIdentifier() },
                blueIdentifier: { CNCursesColorAPI.blueIdentifier() },
                magentaIdentifier: { CNCursesColorAPI.magentaIdentifier() },
                cyanIdentifier: { CNCursesColorAPI.cyanIdentifier() },
                whiteIdentifier: { CNCursesColorAPI.whiteIdentifier() }
            ),
            mouse: .init(
                hasMouseSupport: { CNCursesMouseAPI.hasMouseSupport },
                setMouseMask: { try CNCursesMouseAPI.setMouseMask($0) },
                allEventsMask: { CNCursesMouseAPI.allEventsMask() },
                reportPositionMask: { CNCursesMouseAPI.reportPositionMask() }
            )
        )
    }
}

private final class LockedValue<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withValue<T>(_ body: (inout Value) -> T) -> T {
        lock.withLock {
            body(&value)
        }
    }
}
