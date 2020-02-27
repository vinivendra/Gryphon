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
			Utilities.createFolderIfNeeded(at: TestUtilities.kotlinBuildFolder)
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		AcceptanceTest.setUp()
		testKotlinCompiler()
		test()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testKotlinCompiler", testKotlinCompiler),
		("test", test),
	]

	// MARK: - Tests
	func testKotlinCompiler() {
		XCTAssert(Utilities.fileExists(at: OS.kotlinCompilerPath))
	}

	func test() {
		let tests = TestUtilities.testCasesForAcceptanceTest

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				// Translate the swift code to kotlin
				let testCasePath = TestUtilities.testCasesPath + testName
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(forSwiftFile: testCasePath)
				let defaultFinal = testName.hasSuffix("-default-final")
				let kotlinResults = try Compiler.transpileKotlinCode(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(
					indentationString: "\t",
					defaultFinal: defaultFinal))
				let kotlinCode = kotlinResults[0]
				let kotlinFilePath = "\(TestUtilities.kotlinBuildFolder)/\(testName).kt"
				Utilities.createFile(atPath: kotlinFilePath, containing: kotlinCode)

				// Compile the resulting Kotlin code
				let hue = Shell.runShellCommand(
				OS.kotlinCompilerPath,
				arguments: [
					"-include-runtime", "-d",
					"\(TestUtilities.kotlinBuildFolder)/kotlin.jar",
					kotlinFilePath, ])

				guard let buildCommandResult = hue,
					buildCommandResult.status == 0 else
				{
					XCTFail("Test \(testName) - compilation error. " +
						"It's possible a command timed out.")
					continue
				}

				// Run the compiled binary
				let arguments: MutableList = [
					"java", "-jar",
					"\(TestUtilities.kotlinBuildFolder)/kotlin.jar",
					"-test", "-avoid-unicode", ]
				if defaultFinal {
					arguments.append("--default-final")
				}

				guard let runCommandResult = Shell.runShellCommand(arguments),
					runCommandResult.status == 0,
					runCommandResult.standardError == "" else
				{
					XCTFail("Test \(testName) - execution error. " +
						"It's possible a command timed out.")
					continue
				}

				// Compare the result of running the binary with its expected output

				// Files that don't output anything are just included here to ensure the compilation
				// succeeds and have no file that contains the expected output (since there's no
				// expected output).
				let outputFilePath = testCasePath.withExtension(.output)
				if Utilities.fileExists(at: outputFilePath) {
					let expectedOutput = try! Utilities.readFile(outputFilePath)
					XCTAssert(
						runCommandResult.standardOutput == expectedOutput,
						"Test \(testName): program failed to produce expected result. Diff:" +
							TestUtilities.diff(runCommandResult.standardOutput, expectedOutput))
				}
				else {
					XCTAssert(
						runCommandResult.standardOutput.isEmpty,
						"Test \(testName): expected no output from program. Received output:" +
							runCommandResult.standardOutput)
				}

				print("\t- Done!")
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}
	}
}
