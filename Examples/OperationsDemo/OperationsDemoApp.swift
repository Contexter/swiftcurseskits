import Foundation
import SwiftCursesKit

struct OperationsDemoConfiguration {
  var maximumTicks: Int
  var eventLines: Int
  var shouldPrintPreview: Bool

  init(maximumTicks: Int = 90, eventLines: Int = 8, shouldPrintPreview: Bool = false) {
    self.maximumTicks = max(1, maximumTicks)
    self.eventLines = max(1, eventLines)
    self.shouldPrintPreview = shouldPrintPreview
  }

  static let `default` = OperationsDemoConfiguration()
}

struct OperationsTask {
  enum Event {
    case completed(String)
    case scheduled(String)

    var description: String {
      switch self {
      case let .completed(name):
        return "\(name) completed rollout"
      case let .scheduled(name):
        return "Scheduled \(name)"
      }
    }
  }

  var identifier: Int
  var name: String
  var progress: Double
  var cycleOffset: Int
  private var cooldownRemaining: Int = 0

  init(identifier: Int, name: String, progress: Double, cycleOffset: Int) {
    self.identifier = identifier
    self.name = name
    self.progress = progress
    self.cycleOffset = cycleOffset
    self.cooldownRemaining = 0
  }

  mutating func advance(tick: Int, nextIdentifier: inout Int) -> [Event] {
    var emitted: [Event] = []
    if cooldownRemaining > 0 {
      cooldownRemaining -= 1
      if cooldownRemaining == 0 {
        let newName = "Release #\(nextIdentifier)"
        nextIdentifier += 1
        name = newName
        progress = 0
        emitted.append(.scheduled(newName))
      }
      return emitted
    }
    let radians = (Double(tick + cycleOffset) / 6.0) * (2.0 * .pi)
    let wave = sin(radians)
    let delta = 0.08 + (wave + 1.0) * 0.04
    progress = min(1.0, progress + delta)
    if progress >= 1.0 {
      progress = 1.0
      cooldownRemaining = 2
      emitted.append(.completed(name))
    }
    return emitted
  }

  var statusLabel: String {
    if cooldownRemaining > 0 { return "Complete" }
    switch progress {
    case ..<0.2:
      return "Queued"
    case ..<0.7:
      return "Running"
    case ..<0.999:
      return "Validating"
    default:
      return "Complete"
    }
  }

  var displayProgress: Double { progress }
}

struct OperationsDemoState {
  struct TaskSnapshot {
    var name: String
    var status: String
    var progress: Double
    var isFocused: Bool
  }

  private(set) var tickCount: Int = 0
  private(set) var throughput: Double = 0.55
  private(set) var availability: Double = 0.8
  private(set) var errorBudget: Double = 0.7
  private var tasks: [OperationsTask]
  private var nextIdentifier: Int
  private var focusIndex: Int = 0
  private var eventLog: [String]
  private let eventDisplayLimit: Int

  init(eventDisplayLimit: Int) {
    self.eventDisplayLimit = max(1, eventDisplayLimit)
    self.tasks = (0..<4).map { index in
      OperationsTask(
        identifier: index + 1,
        name: "Release #\(index + 1)",
        progress: Double(index) * 0.18,
        cycleOffset: index * 3
      )
    }
    self.nextIdentifier = tasks.count + 1
    self.eventLog = [
      "Starting operations console…",
      "Synchronizing orchestrators…",
    ]
  }

  var taskSnapshots: [TaskSnapshot] {
    tasks.enumerated().map { index, task in
      TaskSnapshot(
        name: task.name,
        status: task.statusLabel,
        progress: task.displayProgress,
        isFocused: index == focusIndex
      )
    }
  }

  var focusedTaskName: String {
    tasks[focusIndex].name
  }

  var visibleEvents: [String] {
    Array(eventLog.suffix(eventDisplayLimit))
  }

  mutating func focusNextManually() {
    focusIndex = (focusIndex + 1) % max(1, tasks.count)
    log("Operator pinned \(tasks[focusIndex].name)")
  }

  mutating func advanceTick() {
    tickCount += 1
    throughput = Self.waveValue(for: tickCount + 2, period: 14.0, base: 0.62, amplitude: 0.3)
    availability = Self.waveValue(for: tickCount, period: 18.0, base: 0.78, amplitude: 0.18)
    errorBudget = Self.waveValue(for: tickCount + 9, period: 16.0, base: 0.7, amplitude: 0.2)

    var newEvents: [String] = []
    for index in tasks.indices {
      let events = tasks[index].advance(tick: tickCount, nextIdentifier: &nextIdentifier)
      for event in events {
        newEvents.append("Tick \(tickCount): \(event.description)")
      }
    }

    if tickCount % 5 == 0 {
      focusIndex = (focusIndex + 1) % max(1, tasks.count)
      newEvents.append("Tick \(tickCount): Monitoring \(tasks[focusIndex].name)")
    }
    if tickCount % 7 == 0 {
      let action =
        tickCount.isMultiple(of: 14)
        ? "Scale-out request acknowledged"
        : "Autoscaler adjusted compute pool"
      newEvents.append("Tick \(tickCount): \(action)")
    }
    if tickCount % 9 == 0 {
      let budget = Int((errorBudget * 100).rounded())
      newEvents.append("Tick \(tickCount): Error budget holding at \(budget)%")
    }

    if !newEvents.isEmpty {
      eventLog.append(contentsOf: newEvents)
      trimEventLog()
    }
  }

  private mutating func log(_ message: String) {
    eventLog.append(message)
    trimEventLog()
  }

  private mutating func trimEventLog() {
    let maxStorage = max(eventDisplayLimit, 10) * 3
    if eventLog.count > maxStorage {
      eventLog.removeFirst(eventLog.count - maxStorage)
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

struct TaskBoardWidget: Widget {
  var rows: [OperationsDemoState.TaskSnapshot]

  func measure(in constraints: LayoutConstraints) -> LayoutSize {
    let nameWidth = max(12, rows.map { $0.name.count }.max() ?? 12)
    let statusWidth = max(9, rows.map { $0.status.count }.max() ?? 9)
    let baseWidth = 2 + nameWidth + 2 + statusWidth + 2 + 16
    let width = min(constraints.maxWidth, max(constraints.minWidth, baseWidth))
    let height = min(constraints.maxHeight, max(constraints.minHeight, rows.count + 2))
    return LayoutSize(width: max(1, width), height: max(2, height))
  }

  func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
    guard frame.size.width > 0, frame.size.height > 0 else { return }
    let header = formatted(
      prefix: " ",
      name: "Task",
      status: "Status",
      progress: "Progress",
      width: frame.size.width
    )
    buffer.write(header, at: frame.origin, maxWidth: frame.size.width)
    let underline = String(repeating: "-", count: min(frame.size.width, max(4, header.count)))
    buffer.write(
      underline,
      at: LayoutPoint(x: frame.origin.x, y: frame.origin.y + 1),
      maxWidth: frame.size.width
    )

    let maxRows = min(rows.count, max(0, frame.size.height - 2))
    for index in 0..<maxRows {
      let snapshot = rows[index]
      let prefix = snapshot.isFocused ? "➤" : " "
      let percent = "\(Int((snapshot.progress * 100).rounded()))%"
      let progressBar = bar(for: snapshot.progress, width: 16, label: percent)
      let line = formatted(
        prefix: prefix,
        name: snapshot.name,
        status: snapshot.status,
        progress: progressBar,
        width: frame.size.width
      )
      buffer.write(
        line,
        at: LayoutPoint(x: frame.origin.x, y: frame.origin.y + 2 + index),
        maxWidth: frame.size.width
      )
    }
  }

  private func formatted(prefix: String, name: String, status: String, progress: String, width: Int)
    -> String
  {
    let nameColumn = padded(name, to: 18)
    let statusColumn = padded(status, to: 12)
    let progressColumn = padded(progress, to: 20)
    let composed = "\(prefix) \(nameColumn)  \(statusColumn)  \(progressColumn)"
    if composed.count <= width { return composed }
    return String(composed.prefix(width))
  }

  private func padded(_ text: String, to width: Int) -> String {
    if text.count >= width {
      return String(text.prefix(width))
    }
    return text.padding(toLength: width, withPad: " ", startingAt: 0)
  }

  private func bar(for value: Double, width: Int, label: String) -> String {
    let safeWidth = max(6, width)
    let innerWidth = safeWidth - 2
    let progress = min(1.0, max(0.0, value))
    let filled = Int((Double(innerWidth) * progress).rounded())
    let empty = max(0, innerWidth - filled)
    let bar =
      "[" + String(repeating: "#", count: filled) + String(repeating: " ", count: empty) + "]"
    let combined = bar + " " + label
    if combined.count >= safeWidth {
      return String(combined.prefix(safeWidth))
    }
    return combined.padding(toLength: safeWidth, withPad: " ", startingAt: 0)
  }
}

struct OperationsDemo: TerminalApp {
  var configuration: OperationsDemoConfiguration
  private var state: OperationsDemoState

  init(configuration: OperationsDemoConfiguration = .default) {
    self.configuration = configuration
    self.state = OperationsDemoState(eventDisplayLimit: configuration.eventLines)
  }

  var banner: String { "SwiftCursesKit Operations Demo" }

  var body: some Scene {
    Screen {
      VStack(spacing: 1) {
        Title("Operations Console")
        Split(.horizontal, fraction: 0.6) {
          Split(.vertical, fraction: 0.38) {
            VStack(spacing: 1) {
              Title("Service Metrics")
              HStack(spacing: 2) {
                Gauge(title: "Throughput", value: state.throughput)
                Gauge(title: "Availability", value: state.availability)
                Gauge(title: "Error Budget", value: state.errorBudget)
              }
            }
          } trailing: {
            VStack(spacing: 1) {
              Title("Active Workloads")
              WidgetView(TaskBoardWidget(rows: state.taskSnapshots))
            }
          }
        } trailing: {
          VStack(spacing: 1) {
            Title("Recent Events")
            LogView(lines: state.visibleEvents, maximumVisibleLines: configuration.eventLines)
          }
        }
        StatusBar(items: [
          .label("q: quit"),
          .label("n: next focus"),
          .label("Focus: \(state.focusedTaskName)"),
          .label("Tick: \(state.tickCount)"),
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
      switch character.lowercased() {
      case "q":
        await context.quit()
      case "n":
        state.focusNextManually()
      default:
        break
      }
    }
  }
}

struct OperationsDemoPreview {
  var configuration: OperationsDemoConfiguration

  func render(width: Int = 72) -> String {
    var previewState = OperationsDemoState(eventDisplayLimit: configuration.eventLines)
    for _ in 0..<configuration.maximumTicks {
      previewState.advanceTick()
    }
    var lines: [String] = []
    lines.append(Self.centered("Operations Console", width: width))
    lines.append(String(repeating: "=", count: min(width, 40)))
    lines.append("Metrics:")
    lines.append(Self.metricLine(title: "Throughput", value: previewState.throughput, width: width))
    lines.append(
      Self.metricLine(title: "Availability", value: previewState.availability, width: width))
    lines.append(
      Self.metricLine(title: "Error Budget", value: previewState.errorBudget, width: width))
    lines.append("")
    lines.append("Active Workloads:")
    for task in previewState.taskSnapshots {
      lines.append(Self.taskLine(task, width: width))
    }
    lines.append("")
    lines.append("Recent Events:")
    for entry in previewState.visibleEvents {
      lines.append(Self.truncated(entry, width: width))
    }
    lines.append("")
    let status = "q: quit   n: next focus   Ticks: \(previewState.tickCount)"
    lines.append(Self.truncated(status, width: width))
    return lines.joined(separator: "\n")
  }

  private static func metricLine(title: String, value: Double, width: Int) -> String {
    let percent = Int((min(1.0, max(0.0, value)) * 100).rounded())
    let bar = gauge(title: title, value: value, width: max(16, min(width, 48)))
    return truncated("\(bar)  \(percent)%", width: width)
  }

  private static func gauge(title: String, value: Double, width: Int) -> String {
    let safeWidth = max(12, width)
    let progressWidth = max(4, safeWidth - max(title.count + 2, 6))
    let progress = min(1.0, max(0.0, value))
    let filled = Int((Double(progressWidth) * progress).rounded())
    let empty = max(0, progressWidth - filled)
    let bar = String(repeating: "#", count: filled) + String(repeating: " ", count: empty)
    let label = title.padding(
      toLength: max(title.count, safeWidth - progressWidth - 1), withPad: " ", startingAt: 0)
    let composed = "\(label) \(bar)"
    return truncated(composed, width: safeWidth)
  }

  private static func taskLine(_ snapshot: OperationsDemoState.TaskSnapshot, width: Int) -> String {
    let prefix = snapshot.isFocused ? "➤" : " "
    let percent = Int((snapshot.progress * 100).rounded())
    let base = "\(prefix) \(snapshot.name) [\(snapshot.status)] \(percent)%"
    return truncated(base, width: width)
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

enum OperationsDemoArguments {
  case help
  case run(OperationsDemoConfiguration)

  static func parse(_ arguments: [String]) -> OperationsDemoArguments {
    if arguments.contains("--help") || arguments.contains("-h") {
      return .help
    }
    var configuration = OperationsDemoConfiguration.default
    var iterator = arguments.dropFirst().makeIterator()
    while let argument = iterator.next() {
      switch argument {
      case "--ticks":
        if let value = iterator.next(), let parsed = Int(value) {
          configuration.maximumTicks = max(1, parsed)
        }
      case "--event-lines":
        if let value = iterator.next(), let parsed = Int(value) {
          configuration.eventLines = max(1, parsed)
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
    SwiftCursesKit Operations Demo

    Usage: swift run OperationsDemo [options]

      --ticks <count>        Number of tick events before the demo exits (default: 90)
      --event-lines <count>  Number of event log lines to display (default: 8)
      --preview              Print an ASCII snapshot after the demo completes
      -h, --help             Show this help message
    """
  }
}

@main
enum OperationsDemoMain {
  static func main() async {
    switch OperationsDemoArguments.parse(CommandLine.arguments) {
    case .help:
      print(OperationsDemoArguments.helpText)
    case let .run(configuration):
      let app = OperationsDemo(configuration: configuration)
      do {
        _ = try await app.run()
      } catch {
        let message = "Failed to run OperationsDemo: \(error)\n"
        if let data = message.data(using: .utf8) {
          FileHandle.standardError.write(data)
        }
      }
      if configuration.shouldPrintPreview {
        let snapshot = OperationsDemoPreview(configuration: configuration).render()
        print("\n" + snapshot)
      }
    }
  }
}
