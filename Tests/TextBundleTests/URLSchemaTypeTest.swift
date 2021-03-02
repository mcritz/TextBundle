import XCTest
@testable import TextBundle

final class URLSchemaTypeTests: XCTestCase {
    var allTests = [
        ("testURLSchema", testURLSchema),
    ]
    
    func testURLSchema() throws {
        let thisThing = URL.SchemaType("https")
        print(thisThing, thisThing.rawValue)
        XCTAssertEqual(thisThing, URL.SchemaType.network)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileThing = URL.SchemaType(tempDir)
        XCTAssertEqual(fileThing, URL.SchemaType.filesystem)
        
        let noneURL = URL(string: "/var/thing/whatever")!
        let nothing = URL.SchemaType(noneURL)
        XCTAssertEqual(nothing, URL.SchemaType.unknown)
        
        let emptyThing = URL.SchemaType("")
        XCTAssertEqual(emptyThing, URL.SchemaType.none)
    }
}

