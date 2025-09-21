import CNCursesSupport
import Foundation

/// Manages allocation of ncurses color pairs and caches previously configured combinations.
final class ColorPairRegistry: @unchecked Sendable {
    private enum Evaluation {
        case defaultPair
        case cached(ColorPair)
        case allocate(pair: ColorPair, configuration: ColorPairConfiguration, capabilities: TerminalCapabilities)
        case capacityExceeded
    }

    private let lock = NSLock()
    private var capabilities = TerminalCapabilities.headless
    private var cache: [ColorPairConfiguration: ColorPair] = [:]
    private var nextIdentifier: Int16 = 1

    func updateCapabilities(_ capabilities: TerminalCapabilities) {
        lock.withLock {
            self.capabilities = capabilities
            cache.removeAll(keepingCapacity: false)
            nextIdentifier = 1
        }
    }

    func reset() {
        lock.withLock {
            capabilities = .headless
            cache.removeAll(keepingCapacity: false)
            nextIdentifier = 1
        }
    }

    func pair(for configuration: ColorPairConfiguration) throws -> ColorPair {
        let evaluation = lock.withLock { () -> Evaluation in
            let capabilities = self.capabilities
            if configuration.isDefault || !capabilities.supportsColor {
                return .defaultPair
            }
            guard configuration.isSupported(by: capabilities) else {
                return .defaultPair
            }
            if let cached = cache[configuration] {
                return .cached(cached)
            }
            guard nextIdentifier < Int16(capabilities.colorPairCount) else {
                return .capacityExceeded
            }
            let identifier = nextIdentifier
            nextIdentifier += 1
            let pair = ColorPair(rawValue: identifier)
            return .allocate(pair: pair, configuration: configuration, capabilities: capabilities)
        }

        let environment = CNCursesBridge.environment
        switch evaluation {
        case .defaultPair:
            return .default
        case .cached(let pair):
            return pair
        case .allocate(pair: let pair, configuration: let configuration, capabilities: let capabilities):
            let components = configuration.resolvedComponents(for: capabilities)
            do {
                try environment.color.initializePair(pair.rawValue, components.0, components.1)
                lock.withLock {
                    cache[configuration] = pair
                }
            } catch let error as CNCursesRuntimeError {
                lock.withLock {
                    if cache[configuration] == pair {
                        cache.removeValue(forKey: configuration)
                    }
                    if nextIdentifier == pair.rawValue + 1 {
                        nextIdentifier -= 1
                    }
                }
                if case .callFailed(name: _, code: let code) = error {
                    throw ColorPaletteError.ncursesCallFailed(code: code)
                }
                throw ColorPaletteError.ncursesCallFailed(code: -1)
            } catch {
                lock.withLock {
                    if cache[configuration] == pair {
                        cache.removeValue(forKey: configuration)
                    }
                    if nextIdentifier == pair.rawValue + 1 {
                        nextIdentifier -= 1
                    }
                }
                throw ColorPaletteError.ncursesCallFailed(code: -1)
            }
            return pair
        case .capacityExceeded:
            throw ColorPaletteError.capacityExceeded
        }
    }
}
