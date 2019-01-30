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

class GRYTranspilationPassTest: XCTestCase {
	func testPasses() {
		let tests = TestUtils.allTestCases

		do {
			for testName in tests {
				print("- Testing \(testName)...")

				// Fetch the cached Gryphon AST (without passes) and run the passes on it
				let testFilePath = TestUtils.testFilesPath + testName
				let rawAST = try GRYAST.decode(fromFile: testFilePath + .gryRawAST)
				let createdGryphonAST = GRYTranspilationPass.runAllPasses(on: rawAST)

				// Load a cached Gryphon AST (with passes)
				let expectedGryphonAST = try GRYAST.decode(fromFile: testFilePath + .gryAST)

				XCTAssert(
					createdGryphonAST == expectedGryphonAST,
					"Test \(testName): translator failed to produce expected result. Diff:" +
						TestUtils.diff(
							expectedGryphonAST.description, expectedGryphonAST.description))

				print("\t- Done!")
			}

			for warning in GRYTranspilationPass.warnings {
				XCTFail(warning)
			}
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	static var allTests = [
		("testPasses", testPasses),
	]

	static override func setUp() {
		try! GRYUtils.updateTestFiles()
	}
}
