@testable import CNCursesSupport
import XCTest
@testable import SwiftCursesKit

final class TestCNCursesEnvironment: @unchecked Sendable {
    struct DrawCall: Equatable {
        var text: String
        var origin: LayoutPoint
    }

    private(set) var runtimeBootstrapCount = 0
    private(set) var runtimeShutdownCount = 0
    var runtimeIsHeadless = false
    var runtimeBootstrapError: Error?
    var runtimeShutdownError: Error?

    private(set) var standardScreenCallCount = 0
    private(set) var windowDestroyedDescriptors: [CNCursesWindowDescriptor] = []
    var windowSize: (rows: Int, columns: Int) = (24, 80)
    private(set) var clearedCount = 0
    private(set) var stagedCount = 0
    private(set) var commitCount = 0
    private(set) var drawCalls: [DrawCall] = []

    var inputQueue: [Int32] = []
    var noInputCode: Int32 = -1

    var colorHasSupport = false
    var colorStartThrows: Error?
    var colorCountValue = 0
    var colorPairCountValue = 0
    var colorEnableDefaultColors = false
    var colorCanChange = false
    private(set) var initializedPairs: [(Int16, Int16, Int16)] = []

    var mouseHasSupport = false
    private(set) var mouseMasks: [UInt] = []
    var mouseAllEventsMask: UInt = 0
    var mouseReportPositionMask: UInt = 0

    private let descriptor: CNCursesWindowDescriptor

    init() {
        let rawPointer = UnsafeMutableRawPointer(bitPattern: 0x1234)!
        descriptor = CNCursesWindowDescriptor(rawValue: rawPointer)
    }

    func resetCounters() {
        runtimeBootstrapCount = 0
        runtimeShutdownCount = 0
        standardScreenCallCount = 0
        windowDestroyedDescriptors.removeAll()
        clearedCount = 0
        stagedCount = 0
        commitCount = 0
        drawCalls.removeAll()
        initializedPairs.removeAll()
        mouseMasks.removeAll()
    }

    func makeEnvironment() -> CNCursesEnvironment {
        CNCursesEnvironment(
            runtime: .init(
                bootstrap: { [weak self] in
                    guard let self else { return true }
                    if let error = self.runtimeBootstrapError {
                        throw error
                    }
                    self.runtimeBootstrapCount += 1
                    return true
                },
                shutdown: { [weak self] in
                    guard let self else { return }
                    if let error = self.runtimeShutdownError {
                        throw error
                    }
                    self.runtimeShutdownCount += 1
                },
                isHeadless: { [weak self] in
                    self?.runtimeIsHeadless ?? false
                }
            ),
            window: .init(
                standardScreen: { [weak self] in
                    guard let self else {
                        let rawPointer = UnsafeMutableRawPointer(bitPattern: 0x1)!
                        return CNCursesWindowDescriptor(rawValue: rawPointer)
                    }
                    self.standardScreenCallCount += 1
                    return self.descriptor
                },
                destroyWindow: { [weak self] descriptor in
                    self?.windowDestroyedDescriptors.append(descriptor)
                },
                size: { [weak self] _ in
                    guard let self else { return (0, 0) }
                    return self.windowSize
                },
                clear: { [weak self] _ in
                    self?.clearedCount += 1
                },
                draw: { [weak self] text, _, y, x in
                    let origin = LayoutPoint(x: x, y: y)
                    self?.drawCalls.append(DrawCall(text: text, origin: origin))
                },
                stage: { [weak self] _ in
                    self?.stagedCount += 1
                },
                commit: { [weak self] in
                    self?.commitCount += 1
                }
            ),
            input: .init(
                readCharacter: { [weak self] _ in
                    guard let self else { return 0 }
                    if !self.inputQueue.isEmpty {
                        return self.inputQueue.removeFirst()
                    }
                    return self.noInputCode
                },
                noInputCode: { [weak self] in
                    self?.noInputCode ?? -1
                }
            ),
            color: .init(
                hasColorSupport: { [weak self] in
                    self?.colorHasSupport ?? false
                },
                startColor: { [weak self] in
                    if let error = self?.colorStartThrows {
                        throw error
                    }
                },
                colorCount: { [weak self] in
                    self?.colorCountValue ?? 0
                },
                colorPairCount: { [weak self] in
                    self?.colorPairCountValue ?? 0
                },
                enableDefaultColors: { [weak self] in
                    self?.colorEnableDefaultColors ?? false
                },
                canChangeColor: { [weak self] in
                    self?.colorCanChange ?? false
                },
                initializePair: { [weak self] identifier, foreground, background in
                    self?.initializedPairs.append((identifier, foreground, background))
                },
                blackIdentifier: { 0 },
                redIdentifier: { 1 },
                greenIdentifier: { 2 },
                yellowIdentifier: { 3 },
                blueIdentifier: { 4 },
                magentaIdentifier: { 5 },
                cyanIdentifier: { 6 },
                whiteIdentifier: { 7 }
            ),
            mouse: .init(
                hasMouseSupport: { [weak self] in
                    self?.mouseHasSupport ?? false
                },
                setMouseMask: { [weak self] mask in
                    self?.mouseMasks.append(mask)
                },
                allEventsMask: { [weak self] in
                    self?.mouseAllEventsMask ?? 0
                },
                reportPositionMask: { [weak self] in
                    self?.mouseReportPositionMask ?? 0
                }
            )
        )
    }

    func makeScreen() -> TerminalScreen {
        TerminalScreen(rootHandle: WindowHandle(descriptor: descriptor, ownsLifecycle: false))
    }
}
