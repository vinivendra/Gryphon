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

class IntegrationTest: XCTestCase {
	func test() {
		let tests = TestUtils.allTestCases

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Generate kotlin code using the whole compiler
				let testFilePath = TestUtils.testFilesPath + testName
				let generatedKotlinCode =
					try GRYCompiler.generateKotlinCode(forFileAt: testFilePath + .swift)

				// Load the previously stored kotlin code from file
				let expectedKotlinCode = try! String(contentsOfFile: testFilePath + .kt)

				XCTAssert(
					generatedKotlinCode == expectedKotlinCode,
					"Test \(testName): the transpiler failed to produce expected result. Diff:" +
						TestUtils.diff(generatedKotlinCode, expectedKotlinCode))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}

	static var allTests = [
		("test", test),
	]

	override static func setUp() {
		do {
			try GRYUtils.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}
}
