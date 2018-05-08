@testable import GryphonLib
import XCTest

class IntegrationTest: XCTestCase {
	func test() {
		let tests = ["assignments", "bhaskara", "classes", "emptyFunction", "functionCalls", "functionWithEmptyVariable", "functionWithParameters", "functionWithReturn", "functionWithVariable", "ifStatement", "kotlinLiterals", "numericLiterals", "operators", "print", "strings"]
		
		for testName in tests {
			// Generate kotlin code using the whole compiler
			let testFilePath = TestUtils.testFilesPath + testName
			let generatedKotlinCode = GRYCompiler.generateKotlinCode(forFileAt: testFilePath + ".swift")
			
			// Load the previously stored kotlin code from file
			let expectedKotlinCode = try! String(contentsOfFile: testFilePath + ".kt")
			
			XCTAssert(generatedKotlinCode == expectedKotlinCode, "Test \(testName): parser failed to produce expected result. Diff:\n\n===\n\(TestUtils.diff(generatedKotlinCode, expectedKotlinCode))===\n")
		}
	}

	static var allTests = [
		("test", test)
	]
}
