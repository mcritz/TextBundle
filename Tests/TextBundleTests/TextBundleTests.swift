import XCTest
@testable import TextBundle

final class TextBundleTests: XCTestCase {
    func testTextBundle() {
        let bundle = TextBundle(name: "TestValid",
                                contents: "# Hello, World!",
                                assetURLs: nil)
        XCTAssertNotNil(bundle)
    }
    
    func testPack() throws {
        let expectation = XCTestExpectation(description: "Test Pack")
        
        let badURLBundle = TextBundle(name: "Fail", contents: "# Hola, Mundo!", assetURLs: nil)
        let invalidURL = URL(string: "~/invalid/url/path")!
        XCTAssertThrowsError(try badURLBundle.pack(destinationURL: invalidURL) { _ in })
        
        let cacheURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let almostUnique = UUID().uuidString
        let bundle = TextBundle(name: "TestPack-\(almostUnique)", contents: "Konnichiwa Sakyou!", assetURLs: nil)
        XCTAssertNoThrow(try bundle.pack(destinationURL: cacheURL, completion: { didFinish in
            expectation.fulfill()
            XCTAssertTrue(didFinish)
        }))
    }
    
    static var allTests = [
        ("testTextBundle", testTextBundle),
        ("testPack", testPack),
    ]
}
