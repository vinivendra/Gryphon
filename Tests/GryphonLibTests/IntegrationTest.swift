//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// output: Bootstrap/IntegrationTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

// insert: import kotlin.system.exitProcess

class IntegrationTest: XCTestCase {
	// insert: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "IntegrationTest"
	}

	override static func setUp() {
		do {
			try Utilities.updateTestCases()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // annotation: override
		IntegrationTest.setUp()
		test()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // ignore: ignore
		("test", test),
	]

	// MARK: - Tests
	func test() {
		let tests = TestUtilities.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Generate kotlin code using the whole compiler
				let testCasePath = TestUtilities.testCasesPath + testName
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
				let generatedKotlinCode = try Compiler.transpileKotlinCode(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(indentationString: "\t")).first!

				// Load the previously stored kotlin code from file
				let expectedKotlinCode = try! Utilities.readFile(testCasePath.withExtension(.kt))

				XCTAssert(
					generatedKotlinCode == expectedKotlinCode,
					"Test \(testName): the transpiler failed to produce expected result. Diff:" +
						TestUtilities.diff(generatedKotlinCode, expectedKotlinCode))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		let hasOnlyNativeTypeWarnings =
			Compiler.warnings.filter { !$0.contains("Native type") }.isEmpty
		XCTAssert(hasOnlyNativeTypeWarnings)

		if !hasOnlyNativeTypeWarnings || !Compiler.errors.isEmpty {
			Compiler.printErrorsAndWarnings()
		}
	}
}
