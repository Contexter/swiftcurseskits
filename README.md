# SwiftCursesKit

SwiftCursesKit is a Swift-native wrapper around **ncurses** that lets you build rich, windowed dashboards directly in the terminal. It combines ncurses’ battle-tested capabilities (cursor control, colors, mouse input, panels) with ergonomic Swift APIs, async event loops, and declarative layout primitives.

---

## Table of Contents

1. [Features](#features)
2. [Supported Platforms & Capabilities](#supported-platforms--capabilities)
3. [Installing SwiftCursesKit](#installing-swiftcurseskit)
4. [Bootstrapping an App](#bootstrapping-an-app)
5. [Resource & Input Model](#resource--input-model)
6. [Development & Testing Workflow](#development--testing-workflow)
7. [Troubleshooting](#troubleshooting)
8. [Limitations & Roadmap](#limitations--roadmap)
9. [Project Layout](#project-layout)

---

## Features

- **Safe resource management** – Scene and widget wrappers manage ncurses windows and color pairs, automatically initializing and tearing down resources.
- **Declarative layout** – Compose split views, stacks, gauges, tables, and log panes with familiar Swift builders.
- **Async input handling** – Translate keystrokes, mouse events, and timers into structured `KeyEvent`/`MouseEvent` values.
- **Terminal-aware rendering** – Capability detection negotiates wide characters, color pairs, mouse reporting, and resizing at runtime.
- **Examples included** – Sample dashboards demonstrate live metrics, log streaming, and modal dialogs.

---

## Supported Platforms & Capabilities

SwiftCursesKit targets Swift 6.1+ with wide-character ncurses (`ncursesw`). Tested hosts include:

| Platform | Swift Version | ncurses Package | Notes |
| --- | --- | --- | --- |
| Ubuntu 22.04 | 6.1 | `libncursesw5-dev` | Requires UTF-8 locale, e.g. `LANG=en_US.UTF-8`. |
| Debian 12 | 6.1 | `libncursesw6-dev` | Ensure `/usr/lib` contains wide-character libraries. |
| macOS 13+ | 6.1 (Xcode 15 toolchain) | `brew install ncurses` | Export `PKG_CONFIG_PATH=/opt/homebrew/opt/ncurses/lib/pkgconfig`. |

> **Terminal emulators:** 256-color support is auto-detected; fallback rendering reduces gradients when limited colors are available.

---

## Installing SwiftCursesKit

### Prerequisites

- Swift 6.1 or newer
- `ncurses` development headers installed (`sudo apt install libncursesw5-dev` on Debian/Ubuntu, `brew install ncurses` on macOS)

### Add the package dependency

```swift
// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MyTerminalApp",
    dependencies: [
        .package(url: "https://github.com/your-org/SwiftCursesKit.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "MyTerminalApp",
            dependencies: [
                .product(name: "SwiftCursesKit", package: "SwiftCursesKit")
            ]
        )
    ]
)
```

Fetch dependencies and ensure the ncurses headers are discoverable:

```bash
swift package update
swift build
```

If the build cannot locate ncurses, set `PKG_CONFIG_PATH` (macOS/Homebrew) or install the `*-dev` package for your distribution.

---

## Bootstrapping an App

Use ``TerminalApp`` to describe your dashboard and respond to runtime events. The example below mirrors the `Examples/DashboardDemo` executable:

```swift
import SwiftCursesKit

@main
struct DemoDashboard: TerminalApp {
    var cpuUsage: Double = 0.25
    var memoryUsage: Double = 0.24
    var logBuffer: [String] = []

    var body: some Scene {
        Screen {
            VStack(spacing: 1) {
                Title("SwiftCursesKit Demo")
                HStack {
                    Gauge(title: "CPU", value: cpuUsage)
                    Gauge(title: "Memory", value: memoryUsage)
                }
                LogView(lines: logBuffer)
                StatusBar(items: [
                    .label("q: quit"),
                    .label("f: toggle fullscreen")
                ])
            }
            .padding(1)
        }
    }

    mutating func onEvent(_ event: Event, context: AppContext) async {
        switch event {
        case .key(.character("q")):
            await context.quit()
        case .tick:
            cpuUsage = min(1.0, cpuUsage + 0.05)
            memoryUsage = max(0.0, memoryUsage - 0.02)
            logBuffer.append("Tick \(logBuffer.count + 1) processed")
        default:
            break
        }
    }
}
```

Run the demo from the repository root:

```bash
swift run DashboardDemo
```

Pass `--help` to inspect runtime options (tick frequency, preview mode, headless snapshot output, etc.).

### Previewing Layouts

To render a static snapshot without attaching to the terminal, run:

```bash
swift run DashboardDemo --ticks 8 --log-lines 5 --preview
```

This outputs an ASCII capture suitable for CI logs and documentation.

---

## Resource & Input Model

- **Screen & Layout:** The `Screen` scene owns the root ncurses window. Compose `VStack`, `HStack`, `Split`, and widget scenes (`Gauge`, `LogView`, `StatusBar`) to create panes.
- **State Management:** Store application state as mutable properties on your ``TerminalApp`` conformer. Mutations triggered inside ``TerminalApp/onEvent(_:context:)`` will be reflected during the next render pass.
- **Event Handling:** Implement `onEvent(_:context:)` to react to `Event.tick`, key presses, mouse gestures, and resize notifications. Long-running work can spawn `Task`s and post updates via async sequences.
- **Capabilities:** Inspect `context.capabilities` or `context.palette` to determine if colors, mouse reporting, or resize events are active. Provide fallbacks for monochrome terminals and disable unsupported gestures gracefully.

---

## Development & Testing Workflow

SwiftCursesKit’s CI gates mirror the recommended local workflow:

```bash
swift build                          # Validate module interfaces and linking
swift test                           # Execute unit/integration coverage
swift-format --configuration .swift-format.json --in-place .
swift run DashboardDemo --preview    # Render a headless snapshot to ensure ncurses IO works
```

Before submitting patches:

1. Confirm `swift test` passes on Linux and macOS when possible.
2. Exercise the Dashboard demo in an interactive terminal to verify real rendering.
3. Update DocC tutorials and `CHANGELOG.md` entries for user-facing behavior.
4. When cutting a release, duplicate `.github/RELEASE_TEMPLATE.md` into the GitHub release form and summarize highlights consistently.

---

## Troubleshooting

| Symptom | Suggested Fix |
| --- | --- |
| `pkg-config` cannot find ncurses | Ensure `pkg-config --libs ncursesw` succeeds. On macOS set `PKG_CONFIG_PATH=/opt/homebrew/opt/ncurses/lib/pkgconfig`. |
| Garbled characters or missing borders | Confirm the terminal is running in UTF-8 and that wide-character ncurses (`ncursesw`) is installed. |
| Mouse input ignored | Some terminals (e.g., tmux panes without `set -g mouse on`) suppress mouse events. Toggle mouse support or handle `.mouseUnavailable` capability. |
| Snapshot rendering differs from live view | Preview mode limits color depth to avoid escape codes. Launch the example app interactively to confirm gradients and animations. |

If issues persist, file a GitHub issue with your platform, Swift version, terminal emulator, and reproduction steps.

---

## Limitations & Roadmap

- Inline text editing widgets are experimental and may change.
- Accessibility hints (screen readers) are not yet exposed.
- Windows assume a monospaced font; ambiguous-width glyphs may cause misalignment.
- Additional tutorials for multi-window composition and async streams are in progress.

---

## Project Layout

```
.
├── Package.swift
├── Sources
│   ├── SwiftCursesKit        # Public Swift API
│   └── CNCursesSupport       # C shims and unsafe interop
├── Examples
│   └── DashboardDemo         # Reference terminal dashboard
└── Tests
    └── SwiftCursesKitTests   # Unit and integration tests
```

Refer to `AGENTS.md` for detailed contribution standards and safety requirements.

### Formatting

The repository includes a shared `.swift-format.json` profile. Apply it before committing to
keep whitespace and line wrapping consistent across all targets:

```bash
swift-format --configuration .swift-format.json --in-place .
```

Before submitting a pull request:

1. Verify that examples render correctly in a real terminal session.
2. Update DocC tutorials or inline documentation for new features.
3. Add regression tests for bug fixes and new widgets.

---

## Contributing

We welcome issues, feature ideas, and pull requests! Please read `AGENTS.md` for style, testing, and review expectations before contributing. Open a discussion if you plan to propose major architectural changes such as alternate renderers or event loops.

---

## License

SwiftCursesKit is released under the MIT License. See `LICENSE` for details.
