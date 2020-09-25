import XCTest

import Emu6510Tests

var tests = [ XCTestCaseEntry ]()
tests += Emu6510Tests.allTests()
XCTMain(tests)
