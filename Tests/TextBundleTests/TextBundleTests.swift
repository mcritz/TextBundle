import XCTest
@testable import TextBundle

final class TextBundleTests: XCTestCase {
    
    override func tearDown() {
        do {
            let caches = try FileManager.default
                .url(for: .cachesDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: false)
            let matching = try FileManager.default
                .contentsOfDirectory(at: caches,
                                     includingPropertiesForKeys: nil,
                                     options: [
                                        .skipsPackageDescendants,
                                        .skipsHiddenFiles,
                                        .skipsSubdirectoryDescendants
                                     ])
            let pathsToDelete = matching.filter { url in
                return (url.pathExtension == "textbundle")
                    || (url.pathExtension == "textpack")
            }
            pathsToDelete.forEach { deadToMeURL in
                do {
                    try FileManager.default.removeItem(at: deadToMeURL)
                } catch {
                    print("Could not remove test file \(deadToMeURL.path)")
                }
            }
        } catch {
            print("Could not clean up test files.\n\nError:", error.localizedDescription)
        }
    }
    
    func testTextBundle() {
        let bundle = TextBundle(name: "TestValid",
                                contents: "# Hello, World!",
                                assetURLs: nil)
        XCTAssertNotNil(bundle)
    }
    
    func testBundle() throws {
        let badURLBundle = TextBundle(name: "Fail",
                                      contents: "# Hola, Mundo!",
                                      assetURLs: nil)
        let invalidURL = URL(string: "~/invalid/url/path")!
        XCTAssertThrowsError(try badURLBundle.bundle(destinationURL: invalidURL) { _ in })
        
        let cacheURL = try FileManager.default.url(for: .cachesDirectory,
                                                      in: .userDomainMask,
                                                      appropriateFor: nil,
                                                      create: false)
        let almostUnique = UUID().uuidString
        guard let assetURL = Bundle.module.url(forResource: "white_rabbit",
                                               withExtension: "jpg") else {
            XCTFail("couldn’t load resource")
            return
        }
        let textBundleName = "TestPack-\(almostUnique)"
        let bundle = TextBundle(name: textBundleName,
                                contents: markdownString,
                                assetURLs: [assetURL])
        XCTAssertNoThrow(try bundle.bundle(destinationURL: cacheURL) { bundleURL in
            XCTAssertNotNil(bundleURL)
            do {
                let bundleBaseURL = cacheURL.appendingPathComponent(bundle.name.appending(".textbundle"))
                guard let infoJSONData: Data = FileManager.default.contents(atPath: bundleBaseURL.appendingPathComponent("info.json").path) else {
                    XCTFail("could not load info.json")
                    return
                }
                let bundleMetadata = try JSONDecoder().decode(TextBundle.Metadata.self, from: infoJSONData)
                XCTAssertEqual(bundleMetadata.version, 2)
                XCTAssertEqual(bundleMetadata.transient, false)
                
                
                let assetExists: Bool = FileManager.default.fileExists(atPath: bundleBaseURL
                                    .appendingPathComponent("assets")
                                    .appendingPathComponent("white_rabbit.jpg")
                                    .path)
                XCTAssertTrue(assetExists)
                
                // MARK: - Read
                let invalidURL = URL(string: "https://example.com")!
                XCTAssertThrowsError(try TextBundle.read(invalidURL))
                
                let readBundle = try TextBundle.read(bundleURL)
                XCTAssertNotNil(readBundle)
            } catch {
                XCTFail("Could not test bundle contents. \n\nError: \(error.localizedDescription)")
            }
        })
    }
    
    
    func testPack() throws {
        
        guard let rabbitImageURL: URL = Bundle.module.url(forResource: "white_rabbit",
                                                          withExtension: "jpg") else {
            XCTFail("coultn’t load image")
            return
        }

        let testBundleName = "TestBundle-\(UUID().uuidString)"
        let bundle = TextBundle(name: testBundleName,
                                contents: markdownString,
                                assetURLs: [rabbitImageURL])
        let destinationURL = try FileManager.default.url(for: .cachesDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: true)
        try bundle.bundle(destinationURL: destinationURL,
                          compressed: true,
                          progress: { someDouble in
            print(someDouble)
        }) { bundleURL in
            XCTAssertNotNil(bundleURL)
            
            // The created TextBundle should not exist
            let bundleFileName = testBundleName.appending(TextBundle.Constants.bundle.ext)
            let bundleFileURL = bundleURL.deletingLastPathComponent().appendingPathComponent(bundleFileName)
            XCTAssertFalse(FileManager.default.fileExists(atPath: bundleFileURL.path), "The intermediate TextBundle should be deleted when creating a .textpack")
            
            
            do {
                let unpackedBundle = try TextBundle.read(bundleURL)
                XCTAssertNotNil(unpackedBundle)
                XCTAssertEqual(unpackedBundle.name, testBundleName)
                XCTAssertEqual(unpackedBundle.textContents, markdownString)
                XCTAssertEqual(unpackedBundle.meta, bundle.meta)
                let originalFileNames = [rabbitImageURL].map { $0.lastPathComponent }
                let resultFileNames = unpackedBundle.assetURLs?.map { $0.lastPathComponent }
                XCTAssertEqual(resultFileNames, originalFileNames)
            } catch {
                print(error.localizedDescription)
                XCTFail("Error reading unpacked bundle \(error.localizedDescription)")
            }
        }
    }
    
    func testTextBundleRepresentable() {
        struct Dingus: TextBundleRepresentable {
            var name: String
            var textContents: String
            var assetURLS: [URL]?
            var meta: TextBundle.Metadata
        }
        
        let dingus = Dingus(name: "dingus",
                            textContents: "# Dingus",
                            assetURLS: nil,
                            meta: TextBundle.Metadata(1,
                                                      type: "dingus",
                                                      transient: true,
                                                      creatorURL: nil,
                                                      creatorIdentifier: nil,
                                                      sourceURL: nil))
        XCTAssertNotNil(dingus)
    }
    
    static var allTests = [
        ("testTextBundle", testTextBundle),
        ("testBundle", testBundle),
        ("textPack", testPack),
        ("testTextBundleRepresentable", testTextBundleRepresentable),
    ]
    
    let markdownString = """
    # Konnichiwa Sakyou!
    
    ![rabbit](assets/white_rabbit.jpg)
    """
}
