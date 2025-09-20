import XCTest
@testable import SwiftCursesKit

final class SceneLayoutTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        CNCursesBridge.environment = .live
    }

    func testVStackAppliesSpacingAndExpandsWidth() throws {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.windowSize = (rows: 6, columns: 12)
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let screen = environmentDouble.makeScreen()
        let widgetA = RecordingWidget(label: "A", measured: LayoutSize(width: 4, height: 2))
        let widgetB = RecordingWidget(label: "B", measured: LayoutSize(width: 3, height: 2))
        let scene = VStack(spacing: 1) {
            WidgetView(widgetA)
            WidgetView(widgetB)
        }

        let renderer = SceneRenderer()
        try renderer.render(scene: scene, on: screen)

        XCTAssertEqual(environmentDouble.drawCalls.count, 2)
        XCTAssertEqual(environmentDouble.drawCalls[0].origin, LayoutPoint(x: 0, y: 0))
        XCTAssertEqual(environmentDouble.drawCalls[1].origin, LayoutPoint(x: 0, y: 5))
        let verticalLabels = environmentDouble.drawCalls.map { command in
            command.text.trimmingCharacters(in: .whitespaces)
        }
        XCTAssertEqual(verticalLabels, ["A", "B"])
        XCTAssertEqual(environmentDouble.clearedCount, 1)
        XCTAssertEqual(environmentDouble.stagedCount, 1)
        XCTAssertEqual(environmentDouble.commitCount, 1)
    }

    func testSplitDistributesSpaceAccordingToFraction() throws {
        let environmentDouble = TestCNCursesEnvironment()
        environmentDouble.windowSize = (rows: 4, columns: 20)
        CNCursesBridge.environment = environmentDouble.makeEnvironment()

        let screen = environmentDouble.makeScreen()
        let leading = RecordingWidget(label: "Leading", measured: LayoutSize(width: 5, height: 1))
        let trailing = RecordingWidget(label: "Trailing", measured: LayoutSize(width: 5, height: 1))
        let scene = Split(.vertical, fraction: 0.25) {
            WidgetView(leading)
        } trailing: {
            WidgetView(trailing)
        }

        let renderer = SceneRenderer()
        try renderer.render(scene: scene, on: screen)

        XCTAssertEqual(environmentDouble.drawCalls.count, 2)
        XCTAssertEqual(environmentDouble.drawCalls[0].origin.x, 0)
        XCTAssertEqual(environmentDouble.drawCalls[1].origin.x, 5)
        let splitLabels = environmentDouble.drawCalls.map { command in
            command.text.trimmingCharacters(in: .whitespaces)
        }
        XCTAssertEqual(splitLabels, ["Leadi", "Trail"])
    }
}

private struct RecordingWidget: Widget {
    var label: String
    var measured: LayoutSize

    func measure(in constraints: LayoutConstraints) -> LayoutSize {
        LayoutSize(
            width: min(constraints.maxWidth, max(measured.width, constraints.minWidth)),
            height: min(constraints.maxHeight, max(measured.height, constraints.minHeight))
        )
    }

    func render(in frame: LayoutRect, buffer: inout RenderBuffer) {
        guard frame.size.width > 0, frame.size.height > 0 else { return }
        buffer.write(label, at: frame.origin, maxWidth: frame.size.width)
    }
}
