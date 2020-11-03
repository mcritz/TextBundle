import XCTest
@testable import TextBundle

final class TextBundleTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(TextBundle().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
