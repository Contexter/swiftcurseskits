# ``SwiftCursesKit``

@Metadata {
    @Title("SwiftCursesKit")
    @TechnologyRoot
}

Create immersive terminal user interfaces using modern Swift APIs layered on top of ncurses.

## Overview

SwiftCursesKit provides resource-safe wrappers around ncurses concepts like screens and windows. Use ``TerminalApp`` to bootstrap the runtime, coordinate your main loop with ``AppContext``, and compose scenes using layout primitives such as ``VStack`` and ``Gauge``. The runtime tracks terminal capabilities (color depth, mouse reporting, window resizing) so apps can adapt gracefully across platforms.

### Key Concepts

- ``TerminalApp`` defines your entry point and produces a ``Scene`` hierarchy every render pass.
- ``SceneBuilder`` lets you compose layout containers (``VStack``, ``HStack``, ``Split``) and widgets (``Title``, ``LogView``, ``StatusBar``) declaratively.
- ``AppContext`` surfaces information about the running terminal session and allows your app to request shutdown or configure mouse capture.
- ``Event`` delivers timer ticks and key presses. Extend your application to react and mutate state between frames.

---

## Getting Started

### Declaring a Terminal Application

Conform to ``TerminalApp`` and supply a scene describing the UI. Store any mutable state as properties on your type and update them inside ``TerminalApp/onEvent(_:context:)``.

```swift
import SwiftCursesKit

struct Dashboard: TerminalApp {
    var cpuUsage: Double = 0.30
    var memoryUsage: Double = 0.55
    var logs: [String] = []

    var body: some Scene {
        Screen {
            VStack(spacing: 1) {
                Title("Metrics Dashboard")
                HStack(spacing: 2) {
                    Gauge(title: "CPU", value: cpuUsage)
                    Gauge(title: "Memory", value: memoryUsage)
                }
                LogView(lines: logs, maximumVisibleLines: 6)
                StatusBar(items: [.label("q: quit"), .label("tick: update")])
            }
            .padding(1)
        }
    }

    mutating func onEvent(_ event: Event, context: AppContext) async {
        switch event {
        case .key(.character("q")):
            await context.quit()
        case .tick:
            cpuUsage = min(1.0, cpuUsage + 0.02)
            memoryUsage = max(0.0, memoryUsage - 0.01)
            logs.append("Tick \(logs.count + 1) processed")
        }
    }
}
```

Launch the app by calling ``TerminalApp/run()`` from an async context:

```swift
@main
enum EntryPoint {
    static func main() async throws {
        try await Dashboard().run()
    }
}
```

### Inspecting Terminal Capabilities

Query ``AppContext/capabilities`` when tailoring features to the active terminal:

```swift
if context.capabilities.supportsMouse {
    try? context.enableMouseCapture()
}

if !context.capabilities.supportsColor {
    // Fallback to monochrome rendering.
}
```

The provided ``ColorPalette`` exposes common color pairs and adapts to the negotiated depth.

---

## Testing & Previews

- Run your executable with `--preview` (as supported by the `DashboardDemo` example) to emit an ASCII snapshot suitable for CI logs.
- Use `swift run DashboardDemo --ticks 8 --preview` to confirm rendering without attaching to a terminal.
- Execute ``swift build`` and ``swift test`` before distributing releases to ensure both Swift module boundaries and integration tests pass.

---

## Troubleshooting

- **Missing ncurses headers** – Install the `libncursesw*-dev` package on Linux or `brew install ncurses` on macOS, then re-run the build.
- **Garbled characters** – Ensure your locale is UTF-8 and that the wide-character ncurses variant is linked.
- **No mouse events** – Check your terminal emulator configuration; tmux and screen require explicit mouse enablement.

Refer to the README for a complete troubleshooting matrix and release workflow guidance.
