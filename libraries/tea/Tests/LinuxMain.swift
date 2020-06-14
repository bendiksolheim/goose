import XCTest

import teaTests

var tests = [XCTestCaseEntry]()
tests += teaTests.allTests()
XCTMain(tests)
