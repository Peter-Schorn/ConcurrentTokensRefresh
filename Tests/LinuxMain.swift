import XCTest

import ConcurrentTokensRefreshTests

var tests = [XCTestCaseEntry]()
tests += ConcurrentTokensRefreshTests.allTests()
XCTMain(tests)
