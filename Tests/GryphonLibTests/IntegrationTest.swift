@testable import GryphonLib
import XCTest

class IntegrationTest: XCTestCase {
	func test() {
		let tests = TestUtils.allTestCases
		
		for testName in tests {
			print("\t Testing \(testName)...", terminator: "")
			
			// Generate kotlin code using the whole compiler
			let testFilePath = TestUtils.testFilesPath + testName
			let generatedKotlinCode = GRYCompiler.generateKotlinCode(forFileAt: testFilePath + ".swift")
			
			// Load the previously stored kotlin code from file
			let expectedKotlinCode = try! String(contentsOfFile: testFilePath + ".kt")
			
			XCTAssert(generatedKotlinCode == expectedKotlinCode, "Test \(testName): parser failed to produce expected result. Diff:\(TestUtils.diff(generatedKotlinCode, expectedKotlinCode))")
			
			print(" Done!")
		}
	}

	static var allTests = [
		("test", test)
	]
}
