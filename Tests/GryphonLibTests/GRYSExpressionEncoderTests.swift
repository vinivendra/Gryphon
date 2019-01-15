/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

@testable import GryphonLib
import XCTest

class GRYSExpressionEncoderTest: XCTestCase {
	func testEncoder() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			// Load a cached AST from file
			let testFilePath = TestUtils.testFilesPath + testName
			let expectedAST = GRYSwiftAst.initialize(
				fromJsonInFile: testFilePath + .grySwiftAstJson)

			// Write cached AST to file and parse it back
			expectedAST.writeAsSExpression(toFile: testFilePath + .grySwiftAstSExpression)
			let createdAST = GRYSwiftAst(sExpressionFile: testFilePath + .grySwiftAstSExpression)

			// Compare the two
			XCTAssert(
				createdAST == expectedAST,
				"Test \(testName): parser failed to produce expected result. Diff:" +
					TestUtils.diff(createdAST.description, expectedAST.description))

			print("\t- Done!")
		}
	}

	static var allTests = [
		("testEncoder", testEncoder),
	]

	override static func setUp() {
		try! GRYUtils.updateTestFiles()
	}
}
