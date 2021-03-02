import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(TextBundleTests.allTests),
        testCase(URLSchemaTypeTests.allTests),
    ]
}
#endif
