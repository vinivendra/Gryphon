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

// gryphon output: Bootstrap/AcceptanceTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

// gryphon insert: import kotlin.system.exitProcess

class AcceptanceTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	// gryphon annotation: override
	public func getClassName() -> String {
		return "AcceptanceTest"
	}

	override static func setUp() {
		do {
			try TestUtilities.updateASTsForTestCases()
			Utilities.createFolderIfNeeded(at: TestUtilities.kotlinBuildFolder)
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	/// Tests to be run by the translated Kotlin version.
	// gryphon annotation: override
	public func runAllTests() {
		AcceptanceTest.setUp()
		testKotlinCompiler()
		test()
	}

	/// Tests to be run when using Swift on Linux
	// gryphon ignore
	static var allTests = [
		("testKotlinCompiler", testKotlinCompiler),
		("test", test),
	]

	// MARK: - Tests
	func testKotlinCompiler() {
		XCTAssert(Utilities.fileExists(at: OS.kotlinCompilerPath))
	}

	func test() {
		do {
			let defaultToolchain: String? = nil
			let swiftVersion =
				try TranspilationContext.getVersionOfToolchain(defaultToolchain)

			let tests = TestUtilities.testCases

			for testName in tests {
				print("- Testing \(testName)...")
				// Translate the swift code to kotlin
				let testCasePath = TestUtilities.testCasesPath + testName
				let astDumpFilePath =
					SupportingFile.pathOfSwiftASTDumpFile(
						forSwiftFile: testCasePath,
						swiftVersion: swiftVersion)
				let defaultsToFinal = testName.hasSuffix("-default-final")
				let kotlinResults = try Compiler.transpileKotlinCode(
					fromASTDumpFiles: [astDumpFilePath],
					withContext: TranspilationContext(
						toolchainName: nil,
						indentationString: "\t",
						defaultsToFinal: defaultsToFinal))
				let kotlinCode = kotlinResults[0]
				let kotlinFilePath = "\(TestUtilities.kotlinBuildFolder)/\(testName).kt"
				try Utilities.createFile(atPath: kotlinFilePath, containing: kotlinCode)

				// Compile the resulting Kotlin code
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
				if defaultsToFinal {
					arguments.append("--default-final")
				}

				let runCommandResult = Shell.runShellCommand(arguments)
				guard runCommandResult.status == 0,
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
						"Test \(testName): program failed to produce expected result. " +
							"Printing diff ('<' means generated, '>' means expected):" +
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
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}
}
