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

class TranspilationPassTest: XCTestCase {
	func testPasses() {
		let tests = TestUtils.testCasesForTranspilationPassTest

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Fetch the cached Gryphon AST (without passes) and run the passes on it
				let testFilePath = TestUtils.testFilesPath + testName
				let rawAST = try GryphonAST(decodeFromFile: testFilePath + .gryRawAST)
				let createdGryphonAST = TranspilationPass.runAllPasses(on: rawAST)

				// Load a cached Gryphon AST (with passes)
				let expectedGryphonAST = try GryphonAST(decodeFromFile: testFilePath + .gryAST)

				XCTAssert(
					createdGryphonAST == expectedGryphonAST,
					"Test \(testName): translator failed to produce expected result. Diff:" +
						TestUtils.diff(
							expectedGryphonAST.description, expectedGryphonAST.description))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertEqual(Compiler.warnings, [
			"No support for mutable variables in value types: found variable " +
				"mutableVariable inside struct UnsupportedStruct",
			"No support for mutating methods in value types: found method " +
				"mutatingFunction() inside struct UnsupportedStruct",
			"No support for mutating methods in value types: found method " +
				"mutatingFunction() inside enum UnsupportedEnum",
			])
	}

	static var allTests = [
		("testPasses", testPasses),
	]

	override static func setUp() {
		do {
			try Utilities.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	override func setUp() {
		Compiler.clearErrorsAndWarnings()
	}
}
