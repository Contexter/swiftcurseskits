import XCTest

@testable import OperationsDemo

final class OperationsDemoIntegrationTests: XCTestCase {
  func testPreviewContainsKeySections() {
    let configuration = OperationsDemoConfiguration(
      maximumTicks: 6, eventLines: 5, shouldPrintPreview: true)
    let preview = OperationsDemoPreview(configuration: configuration).render(width: 70)
    XCTAssertTrue(preview.contains("Operations Console"))
    XCTAssertTrue(preview.contains("Active Workloads"))
    XCTAssertTrue(preview.contains("Ticks: 6"))
  }
}
