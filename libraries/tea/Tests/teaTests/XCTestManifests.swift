import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ContainerRenderingTests.allTests),
        testCase(ContainerUpdateTests.allTests),
        testCase(CollapseViewRenderingTests.allTests)
    ]
}
#endif
