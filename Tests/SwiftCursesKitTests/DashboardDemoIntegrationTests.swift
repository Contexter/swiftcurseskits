import XCTest
@testable import DashboardDemo

final class DashboardDemoIntegrationTests: XCTestCase {
    func testPreviewIncludesTitleAndStatus() {
        let configuration = DemoDashboardConfiguration(
            maximumTicks: 5, logLines: 4, shouldPrintPreview: true)
        let preview = DashboardDemoPreview(configuration: configuration).render(width: 60)
        XCTAssertTrue(preview.contains("SwiftCursesKit Demo"))
        XCTAssertTrue(preview.contains("Ticks: 5"))
    }
}
