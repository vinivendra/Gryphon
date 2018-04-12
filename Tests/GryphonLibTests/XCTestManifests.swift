import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GRYExtensionTest.allTests),
		testCase(GRYUtilsTest.allTests),
		testCase(GRYShellTest.allTests),
		testCase(GRYPrintableAsTreeTest.allTests)
    ]
}
#endif
