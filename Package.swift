// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SwiftCursesKit",
    platforms: [
        .macOS(.v13),
        .tvOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SwiftCursesKit",
            targets: ["SwiftCursesKit"]
        )
    ],
    targets: [
        .target(
            name: "SwiftCursesKit",
            dependencies: ["CNCursesSupport"],
            path: "Sources/SwiftCursesKit"
        ),
        .target(
            name: "CNCursesSupport",
            dependencies: ["CNCursesSupportShims"],
            path: "Sources/CNCursesSupport/Swift",
            linkerSettings: [
                .linkedLibrary("ncursesw")
            ]
        ),
        .systemLibrary(
            name: "CNCursesSupportShims",
            path: "Sources/CNCursesSupport/Shims",
            pkgConfig: "ncursesw",
            providers: [
                .brew(["ncurses"]),
                .apt(["libncursesw5-dev"]),
            ]
        ),
        .executableTarget(
            name: "DashboardDemo",
            dependencies: ["SwiftCursesKit"],
            path: "Examples/DashboardDemo"
        ),
        .testTarget(
            name: "SwiftCursesKitTests",
            dependencies: [
                "SwiftCursesKit",
                "DashboardDemo",
            ],
            path: "Tests/SwiftCursesKitTests"
        ),
    ]
)
