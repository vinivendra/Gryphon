@testable import GryphonLib
import XCTest

class GRYKotlinTranslatorTest: XCTestCase {
	func testTranslator() {
		let tests = TestUtils.allTestCases
		
		for testName in tests {
			print("\t Testing \(testName)...", terminator: "")
			
			// Create the Kotlin code using the mock AST
			let testFilePath = TestUtils.testFilesPath + testName
			let ast = GRYAst.initialize(fromJsonInFile: testFilePath + ".json")
			let createdKotlinCode = GRYKotlinTranslator().translateAST(ast)
			
			// Load the previously stored Kotlin code from file
			let expectedKotlinCode = try! String(contentsOfFile: testFilePath + ".kt")
			
			XCTAssert(createdKotlinCode == expectedKotlinCode, "Test \(testName): translator failed to produce expected result. Diff:\n\n===\n\(TestUtils.diff(createdKotlinCode, expectedKotlinCode))===\n")
			
			print(" Done!")
		}
	}

	static var allTests = [
		("testTranslator", testTranslator)
	]
}
