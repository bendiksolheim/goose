import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(gitLibTests.allTests),
        testCase(DiffParseTests.allTests)
    ]
}
#endif
