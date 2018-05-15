@testable import GryphonLib
import XCTest

class AcceptanceTest: XCTestCase {
	func test() {
		let tests = TestUtils.acceptanceTestCases
		
		for testName in tests {
			print("\t Testing \(testName)...", terminator: "")
			
			// Translate the swift code to kotlin, compile the resulting kotlin code, run it, and get its output
			let testFilePath = TestUtils.testFilesPath + testName
			let compilationResult = GRYCompiler.compileAndRun(fileAt: testFilePath + ".swift")
			
			switch compilationResult {
			case let .failure(errorMessage: errorMessage):
				XCTFail("Test \(testName) - compilation error. \(errorMessage)")
				continue
			case let .success(commandOutput: compilerResult):
				// Load the previously stored kotlin code from file
				let expectedOutput = try! String(contentsOfFile: testFilePath + ".output")
				
				XCTAssert(compilerResult.standardError == "", "Test \(testName): the compiler encountered an error: \(compilerResult.standardError).")
				XCTAssert(compilerResult.status == 0, "Test \(testName): the compiler exited with value \(compilerResult.status).")
				XCTAssert(compilerResult.standardOutput == expectedOutput, "Test \(testName): parser failed to produce expected result. Diff:\(TestUtils.diff(compilerResult.standardOutput, expectedOutput))")
				
				print(" Done!")
			}
		}
	}
	
	static var allTests = [
		("test", test)
	]
}
