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
        let badURLBundle = TextBundle(name: "Fail", contents: "# Hola, Mundo!", assetURLs: nil)
        let invalidURL = URL(string: "~/invalid/url/path")!
        XCTAssertThrowsError(try badURLBundle.pack(destinationURL: invalidURL) { _ in })
        
        let cacheURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let almostUnique = UUID().uuidString
        guard let assetURL = Bundle.module.url(forResource: "white_rabbit", withExtension: "jpg") else {
            XCTFail("couldn’t load resource")
            return
        }
        let textBundleName = "TestPack-\(almostUnique)"
        let bundle = TextBundle(name: textBundleName, contents: markdownString, assetURLs: [assetURL])
        XCTAssertNoThrow(try bundle.pack(destinationURL: cacheURL, completion: { didFinish in
            XCTAssertTrue(didFinish)
            print(cacheURL)
            do {
                let bundleBaseURL = cacheURL.appendingPathComponent(bundle.name.appending(".textbundle"))
                guard let infoJSONData: Data = FileManager.default.contents(atPath: bundleBaseURL.appendingPathComponent("info.json").path) else {
                    XCTFail("could not load info.json")
                    return
                }
                let bundleMetadata = try JSONDecoder().decode(TextBundle.Metadata.self, from: infoJSONData)
                XCTAssertEqual(bundleMetadata.version, 3)
                XCTAssertEqual(bundleMetadata.transient, false)
                
                
                let assetExists: Bool = FileManager.default.fileExists(atPath: bundleBaseURL
                                    .appendingPathComponent("assets")
                                    .appendingPathComponent("white_rabbit.jpg")
                                    .path)
                XCTAssertTrue(assetExists)
            } catch {
                XCTFail("Could not test bundle contents")
            }
        }))
    }
    
    static var allTests = [
        ("testTextBundle", testTextBundle),
        ("testPack", testPack),
    ]
    
    let markdownString = """
        # Konnichiwa Sakyou!
        
        ![rabbit]([assets/guillermo-casales-LQfcolSv2M0-unsplash.jpg)
    """
}
