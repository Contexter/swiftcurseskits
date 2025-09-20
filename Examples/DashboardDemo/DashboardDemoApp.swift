import Foundation
import SwiftCursesKit

struct DemoDashboardConfiguration {
  var maximumTicks: Int
  var logLines: Int
  var shouldPrintPreview: Bool

  init(maximumTicks: Int = 60, logLines: Int = 6, shouldPrintPreview: Bool = false) {
    self.maximumTicks = max(1, maximumTicks)
    self.logLines = max(1, logLines)
    self.shouldPrintPreview = shouldPrintPreview
  }

  static let `default` = DemoDashboardConfiguration()
}

struct DemoDashboardState {
  private(set) var cpuUsage: Double = 0.35
  private(set) var memoryUsage: Double = 0.52
  private(set) var tickCount: Int = 0
  private var logStorage: [String]
  private let logDisplayLimit: Int

  init(logDisplayLimit: Int) {
    self.logDisplayLimit = max(1, logDisplayLimit)
    self.logStorage = [
      "Starting dashboard runtime…",
      "Connecting to telemetry stream…",
    ]
  }

  var visibleLogs: [String] {
    Array(logStorage.suffix(logDisplayLimit))
  }

  mutating func advanceTick() {
    tickCount += 1
    cpuUsage = Self.waveValue(for: tickCount, period: 12.0, base: 0.55, amplitude: 0.35)
    memoryUsage = Self.waveValue(for: tickCount + 4, period: 18.0, base: 0.5, amplitude: 0.3)
    let cpuPercent = Int((cpuUsage * 100).rounded())
    let memoryPercent = Int((memoryUsage * 100).rounded())
    let message: String
    switch tickCount % 4 {
    case 0:
      message = "Sampling sensors…"
    case 1:
      message = "CPU load steady at \(cpuPercent)%"
    case 2:
      message = "Memory pressure at \(memoryPercent)%"
    default:
      message = "Tick \(tickCount) processed"
    }
    appendLog("Tick \(tickCount): \(message)")
  }

  private mutating func appendLog(_ message: String) {
    logStorage.append(message)
    let maxStorage = max(logDisplayLimit, 10) * 3
    if logStorage.count > maxStorage {
      logStorage.removeFirst(logStorage.count - maxStorage)
    }
  }

  private static func waveValue(for tick: Int, period: Double, base: Double, amplitude: Double)
    -> Double
  {
    let radians = (Double(tick) / period) * (2.0 * .pi)
    let offset = sin(radians)
    let clamped = base + amplitude * offset
    return min(1.0, max(0.0, clamped))
  }
}

struct DemoDashboard: TerminalApp {
  var configuration: DemoDashboardConfiguration
  private var state: DemoDashboardState

  init(configuration: DemoDashboardConfiguration = .default) {
    self.configuration = configuration
    self.state = DemoDashboardState(logDisplayLimit: configuration.logLines)
  }

  var banner: String { "SwiftCursesKit Dashboard Demo" }

  var body: some Scene {
    Screen {
      VStack(spacing: 1) {
        Title("SwiftCursesKit Demo")
        HStack(spacing: 4) {
          Gauge(title: "CPU", value: state.cpuUsage)
          Gauge(title: "Memory", value: state.memoryUsage)
        }
        LogView(lines: state.visibleLogs, maximumVisibleLines: configuration.logLines)
        StatusBar(items: [
          .label("q: quit"),
          .label("Ticks: \(state.tickCount)"),
        ])
      }
      .padding(1)
    }
  }

  mutating func onEvent(_ event: Event, context: AppContext) async {
    switch event {
    case .tick:
      state.advanceTick()
      if state.tickCount >= configuration.maximumTicks {
        await context.quit()
      }
    case let .key(.character(character)):
      if character == "q" || character == "Q" {
        await context.quit()
      }
    }
  }
}

struct DashboardDemoPreview {
  var configuration: DemoDashboardConfiguration

  func render(width: Int = 64) -> String {
    var previewState = DemoDashboardState(logDisplayLimit: configuration.logLines)
    for _ in 0..<configuration.maximumTicks {
      previewState.advanceTick()
    }
    var lines: [String] = []
    lines.append(Self.centered("SwiftCursesKit Demo", width: width))
    lines.append(String(repeating: "=", count: min(width, 32)))
    lines.append(
      contentsOf: gaugeBlock(
        title: "CPU",
        value: previewState.cpuUsage,
        pairedWithTitle: "Memory",
        pairedValue: previewState.memoryUsage,
        width: width
      ))
    lines.append("")
    lines.append("Logs:")
    for entry in previewState.visibleLogs {
      lines.append(Self.truncated(entry, width: width))
    }
    lines.append("")
    let status = "q: quit   Ticks: \(previewState.tickCount)"
    lines.append(Self.truncated(status, width: width))
    return lines.joined(separator: "\n")
  }

  private func gaugeBlock(
    title: String,
    value: Double,
    pairedWithTitle otherTitle: String,
    pairedValue otherValue: Double,
    width: Int
  ) -> [String] {
    let gaugeWidth = max(16, (width - 4) / 2)
    let first = Self.gaugeLines(title: title, value: value, width: gaugeWidth)
    let second = Self.gaugeLines(title: otherTitle, value: otherValue, width: gaugeWidth)
    let padding = String(repeating: " ", count: max(0, width - (gaugeWidth * 2 + 4)))
    return zip(first, second).map { left, right in
      let composed = left + "    " + right
      if composed.count < width {
        return composed + padding.prefix(width - composed.count)
      }
      return String(composed.prefix(width))
    }
  }

  private static func gaugeLines(title: String, value: Double, width: Int) -> [String] {
    let safeWidth = max(4, width)
    let barWidth = max(0, safeWidth - 2)
    let progress = min(1.0, max(0.0, value))
    let filled = Int((Double(barWidth) * progress).rounded())
    let empty = max(0, barWidth - filled)
    let titleLine = truncated(title, width: safeWidth)
    let barLine =
      "[" + String(repeating: "#", count: filled) + String(repeating: " ", count: empty) + "]"
    let percent = "\(Int((progress * 100).rounded()))%"
    let labelLine = percent.padding(toLength: safeWidth, withPad: " ", startingAt: 0)
    return [
      titleLine,
      truncated(barLine, width: safeWidth),
      truncated(labelLine, width: safeWidth),
    ]
  }

  private static func centered(_ text: String, width: Int) -> String {
    guard text.count < width else { return truncated(text, width: width) }
    let remaining = width - text.count
    let leading = remaining / 2
    let trailing = remaining - leading
    return String(repeating: " ", count: leading) + text
      + String(repeating: " ", count: trailing)
  }

  private static func truncated(_ text: String, width: Int) -> String {
    guard width > 0 else { return "" }
    if text.count >= width {
      return String(text.prefix(width))
    }
    return text.padding(toLength: width, withPad: " ", startingAt: 0)
  }
}

enum DashboardDemoArguments {
  case help
  case run(DemoDashboardConfiguration)

  static func parse(_ arguments: [String]) -> DashboardDemoArguments {
    if arguments.contains("--help") || arguments.contains("-h") {
      return .help
    }
    var configuration = DemoDashboardConfiguration.default
    var iterator = arguments.dropFirst().makeIterator()
    while let argument = iterator.next() {
      switch argument {
      case "--ticks":
        if let value = iterator.next(), let parsed = Int(value) {
          configuration.maximumTicks = max(1, parsed)
        }
      case "--log-lines":
        if let value = iterator.next(), let parsed = Int(value) {
          configuration.logLines = max(1, parsed)
        }
      case "--preview":
        configuration.shouldPrintPreview = true
      default:
        continue
      }
    }
    return .run(configuration)
  }

  static var helpText: String {
    """
    SwiftCursesKit Dashboard Demo

    Usage: swift run DashboardDemo [options]

      --ticks <count>      Number of tick events before the demo exits (default: 60)
      --log-lines <count>  Number of log lines to display in the log view (default: 6)
      --preview            Print an ASCII snapshot after the demo completes
      -h, --help           Show this help message
    """
  }
}

@main
enum DashboardDemoMain {
  static func main() async {
    switch DashboardDemoArguments.parse(CommandLine.arguments) {
    case .help:
      print(DashboardDemoArguments.helpText)
    case let .run(configuration):
      let app = DemoDashboard(configuration: configuration)
      do {
        _ = try await app.run()
      } catch {
        let message = "Failed to run DashboardDemo: \(error)\n"
        if let data = message.data(using: .utf8) {
          FileHandle.standardError.write(data)
        }
      }
      if configuration.shouldPrintPreview {
        let snapshot = DashboardDemoPreview(configuration: configuration).render()
        print("\n" + snapshot)
      }
    }
  }
}
