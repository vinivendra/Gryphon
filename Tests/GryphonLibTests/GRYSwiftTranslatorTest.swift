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

class GRYSwiftTranslatorTest: XCTestCase {
	func testTranslator() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Create a new Gryphon AST from the cached Swift AST using the GRYSwiftTranslator
				let testFilePath = TestUtils.testFilesPath + testName
				let swiftAst = GRYSwiftAst.initialize(
					fromJsonInFile: testFilePath + .grySwiftAstJson)
				let createdGryphonRawAst = try GRYSwift4Translator().translateAST(swiftAst)

				// Load a cached Gryphon AST from file
				let expectedGryphonRawAstJson = try! String(
					contentsOfFile: testFilePath + .gryRawAstJson)
				let expectedGryphonRawAstData = Data(expectedGryphonRawAstJson.utf8)
				let expectedGryphonRawAst =
					try! JSONDecoder().decode(GRYAst.self, from: expectedGryphonRawAstData)

				// Compare the two
				XCTAssert(
					createdGryphonRawAst == expectedGryphonRawAst,
					"Test \(testName): translator failed to produce expected result. Diff:" +
						TestUtils.diff(
							createdGryphonRawAst.description, expectedGryphonRawAst.description))

				print("\t- Done!")
			}
			catch let error {
				if let error = error as? GRYPrintableError {
					error.print()
					XCTFail()
					continue
				}
				else {
					print("Unexpected error: \(error)")
					fatalError()
				}
			}
		}
	}

	static var allTests = [
		("testTranslator", testTranslator),
	]

	static override func setUp() {
		try! TestUtils.updateFiles()
	}
}
