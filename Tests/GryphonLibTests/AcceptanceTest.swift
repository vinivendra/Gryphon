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

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

// gryphon insert: import kotlin.system.exitProcess

class AcceptanceTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "AcceptanceTest"
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
	public func runAllTests() { // gryphon annotation: override
		AcceptanceTest.setUp()
		test()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
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
				let testCasePath = TestUtilities.testCasesPath + testName
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
				let defaultFinal = testName.hasSuffix("--default-final")
				guard let compilationResult = try Compiler.transpileCompileAndRun(
					ASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(
						indentationString: "\t",
						defaultFinal: defaultFinal)) else
				{
					XCTFail("Test \(testName) - compilation error. " +
						"It's possible a command timed out.")
					continue
				}

				// Load the previously stored kotlin code from file

				XCTAssert(
					compilationResult.standardError == "",
					"Test \(testName): the compiler encountered an error: " +
					"\(compilationResult.standardError).")
				XCTAssert(
					compilationResult.status == 0,
					"Test \(testName): the compiler exited with value " +
					"\(compilationResult.status).")

				// Files that don't output anything are just included here to ensure the compilation
				// succeeds and have no file that contains the expected output (since there's no
				// expected output).
				let outputFilePath = testCasePath.withExtension(.output)
				if Utilities.fileExists(at: outputFilePath) {
					let expectedOutput = try! Utilities.readFile(outputFilePath)
					XCTAssert(
						compilationResult.standardOutput == expectedOutput,
						"Test \(testName): program failed to produce expected result. Diff:" +
							TestUtilities.diff(compilationResult.standardOutput, expectedOutput))
				}
				else {
					XCTAssert(
						compilationResult.standardOutput.isEmpty,
						"Test \(testName): expected no output from program. Received output:" +
							compilationResult.standardOutput)
				}

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}
}
