//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import GryphonLib
import XCTest

class AcceptanceTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("testKotlinCompiler", testKotlinCompiler),
		("test", test),
	]

	override static func setUp() {
		Utilities.createFolderIfNeeded(at: TestUtilities.kotlinBuildFolder)
	}

	// MARK: - Tests
	func testKotlinCompiler() {
		XCTAssert(Utilities.fileExists(at: OS.kotlinCompilerPath))
	}

	func test() {
		let tests = TestUtilities.sortedTests

		for testName in tests {
			print("- Testing \(testName)...")

			// Compile the Kotlin code
			let testCasePath = TestUtilities.testCasesPath + testName

			let kotlinFilePath = (testCasePath + "-swiftSyntax").withExtension(.kt)

			let commandResult = Shell.runShellCommand(
				OS.kotlinCompilerPath,
				arguments: [
					"-include-runtime", "-d",
					"\(TestUtilities.kotlinBuildFolder)/kotlin.jar",
					kotlinFilePath, ])

			guard commandResult.status == 0 else {
				XCTFail("Test \(testName) - compilation error:\n" +
					commandResult.standardOutput +
					commandResult.standardError)
				continue
			}

			// Run the compiled binary
			let arguments: MutableList = [
				"java", "-jar",
				"\(TestUtilities.kotlinBuildFolder)/kotlin.jar",
				"-test", "-avoid-unicode", ]

			let defaultsToFinal = testName.contains("-default-final")
			if defaultsToFinal {
				arguments.append("--default-final")
			}

			let runCommandResult = Shell.runShellCommand(arguments)
			guard runCommandResult.status == 0,
				  runCommandResult.standardError == "" else
			{
				XCTFail("Test \(testName) - execution error. It's possible a command timed out.")
				continue
			}

			// Compare the result of running the binary with its expected output

			// Files that don't output anything are just included here to ensure the compilation
			// succeeds and have no file that contains the expected output (since there's no
			// expected output).
			let outputFilePath = testCasePath.withExtension(.output)
			if Utilities.fileExists(at: outputFilePath) {
				let expectedOutput = try! Utilities.readFile(outputFilePath)
				if runCommandResult.standardOutput != expectedOutput {
					XCTFail("Test \(testName): program failed to produce expected result. " +
						"Printing diff ('<' means generated, '>' means expected):" +
						TestUtilities.diff(runCommandResult.standardOutput, expectedOutput))
				}
			}
			else {
				if !runCommandResult.standardOutput.isEmpty {
					XCTFail("Test \(testName): expected no output from program. Received output:" +
						runCommandResult.standardOutput)
				}
			}

			print("\t- Done!")
		}
	}
}
