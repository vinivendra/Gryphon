@testable import GryphonLib
import XCTest

class AcceptanceTest: XCTestCase {
	func test() {
		let tests = ["bhaskara", "ifStatement", "kotlinLiterals", "numericLiterals", "operators", "print"]
		
		for testName in tests {
			// Translate the swift code to kotlin, compile the resulting kotlin code, run it, and get its output
			let testFilePath = TestUtils.testFilesPath + testName
			let compilerOutput = GRYCompiler.compileAndRun(fileAt: testFilePath + ".swift")
			
			// Load the previously stored kotlin code from file
			let expectedOutput = try! String(contentsOfFile: testFilePath + ".output")
			
			XCTAssert(compilerOutput.standardError == "", "Test \(testName): the compiler encountered an error: \(compilerOutput.standardError).")
			XCTAssert(compilerOutput.status == 0, "Test \(testName): the compiler exited with value \(compilerOutput.status).")
			XCTAssert(compilerOutput.standardOutput == expectedOutput, "Test \(testName): parser failed to produce expected result. Diff:\n\n===\n\(TestUtils.diff(compilerOutput.standardOutput, expectedOutput))===\n")
		}
	}
	
	static var allTests = [
		("test", test)
	]
}
