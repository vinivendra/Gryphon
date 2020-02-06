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

// gryphon output: Bootstrap/AcceptanceTest.kt

#if !IS_DUMPING_ASTS
@testable import GryphonLib
import XCTest
#endif

// declaration: import kotlin.system.exitProcess

class AcceptanceTest: XCTestCase {
	// declaration: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "AcceptanceTest"
	}

	override static func setUp() {
		do {
			try Utilities.updateTestFiles()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // annotation: override
		AcceptanceTest.setUp()
		test()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // kotlin: ignore
		("test", test),
	]

	// MARK: - Tests
	func test() {
		let tests = TestUtilities.testCasesForAcceptanceTest

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Translate the swift code to kotlin, compile the resulting kotlin code, run it,
				// and get its output
				let testFilePath = TestUtilities.testFilesPath + testName
				let astDumpFilePath = Utilities.pathOfSwiftASTDumpFile(forSwiftFile: testFilePath)
				guard let compilationResult = try Compiler.transpileCompileAndRun(
					ASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(indentationString: "\t")) else
				{
					XCTFail("Test \(testName) - compilation error. " +
						"It's possible a command timed out.")
					continue
				}

				// Load the previously stored kotlin code from file
				let expectedOutput = try! Utilities.readFile(testFilePath.withExtension(.output))

				XCTAssert(
					compilationResult.standardError == "",
					"Test \(testName): the compiler encountered an error: " +
					"\(compilationResult.standardError).")
				XCTAssert(
					compilationResult.status == 0,
					"Test \(testName): the compiler exited with value " +
					"\(compilationResult.status).")
				XCTAssert(
					compilationResult.standardOutput == expectedOutput,
					"Test \(testName): program failed to produce expected result. Diff:" +
						TestUtilities.diff(compilationResult.standardOutput, expectedOutput))

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}
}
