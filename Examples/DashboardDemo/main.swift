import SwiftCursesKit

/// Bootstraps the minimal dashboard demo.
@main
struct DashboardDemo {
    static func main() {
        do {
            let app = TerminalApp()
            let banner = try app.run()
            print("Launching: \(banner)")
        } catch {
            print("Failed to start SwiftCursesKit demo: \(error)")
        }
    }
}
