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
            path: "Sources/CNCursesSupport"
        ),
        .executableTarget(
            name: "DashboardDemo",
            dependencies: ["SwiftCursesKit"],
            path: "Examples/DashboardDemo"
        ),
        .testTarget(
            name: "SwiftCursesKitTests",
            dependencies: ["SwiftCursesKit"],
            path: "Tests/SwiftCursesKitTests"
        ),
    ]
)
