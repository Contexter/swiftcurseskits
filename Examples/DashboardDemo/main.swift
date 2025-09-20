import SwiftCursesKit

struct DemoDashboard: TerminalApp {
    var banner: String { "Dashboard Demo" }

    var body: some Scene {
        Screen {
            VStack(spacing: 1) {
                Title("SwiftCursesKit Demo")
                HStack(spacing: 2) {
                    Gauge(title: "CPU", value: cpuUsage)
                    Gauge(title: "Memory", value: memoryUsage)
                }
                LogView(lines: logLines, maximumVisibleLines: 5)
                StatusBar(items: [
                    .label("q: quit"),
                    .label("Tick count: \(tickCount)"),
                ])
            }
            .padding(1)
        }
    }

    private var cpuUsage: Double = 0.35
    private var memoryUsage: Double = 0.52
    private var tickCount: Int = 0
    private var logLines: [String] = [
        "Starting dashboard runtime",
        "Rendering static preview",
    ]

    mutating func onEvent(_ event: Event, context: AppContext) async {
        switch event {
        case .tick:
            tickCount += 1
            if tickCount > 1 {
                await context.quit()
            }
        default:
            break
        }
    }
}

@main
enum DashboardDemo {
    static func main() async {
        let app = DemoDashboard()
        do {
            let banner = try await app.run()
            print("Launching: \(banner)")
        } catch {
            print("Failed to start SwiftCursesKit demo: \(error)")
        }
    }
}
