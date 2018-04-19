@testable import GryphonLib
import XCTest

class GRYKotlinTranslatorTest: XCTestCase {
	func testTranslator() {
		let tests = ["emptyFunction", "functionWithEmptyVariable", "functionWithParameters", "functionWithReturn", "functionWithVariable"]
		
		for testName in tests {
			// Create the Kotlin code using the mock AST
			let testFilePath = TestUtils.testFilesPath + testName
			let astRawJSON = try! String(contentsOfFile: testFilePath + ".json")
			let astProcessedJSON = Utils.replacePlaceholders(in: astRawJSON, withFilePath: testFilePath + ".swift")
			let astData = Data(astProcessedJSON.utf8)
			let ast = try! JSONDecoder().decode(GRYAst.self, from: astData)
			let createdKotlinCode = GRYKotlinTranslator().translateAST(ast)
			
			// Load the previously stored Kotlin code from file
			let expectedKotlinCode = try! String(contentsOfFile: testFilePath + ".kt")
			
			XCTAssertEqual(createdKotlinCode, expectedKotlinCode, "Test \(testName): translator failed to produce expected result. Diff:\n\n===\n\(TestUtils.diff(createdKotlinCode, expectedKotlinCode))===\n")
		}
	}

	static var allTests = [
		("testTranslator", testTranslator)
	]
}
