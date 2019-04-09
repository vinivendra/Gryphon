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

class BootstrappingTest: XCTestCase {
	func test() {
		Compiler.clearErrorsAndWarnings()
		defer {
			XCTAssertFalse(Compiler.hasErrorsOrWarnings())
			Compiler.printErrorsAndWarnings()
		}

		// Dump the ASTs
		print("\t* Dumping the ASTs...")
		let dumpCommand = ["perl", "dumpTranspilerAST.pl" ]
		guard let dumpResult = Shell.runShellCommand(dumpCommand) else {
			XCTFail("Timed out.")
			return
		}
		guard dumpResult.status == 0 else {
			XCTFail("Failed to dump ASTs.\n" +
				"Output:\n\(dumpResult.standardOutput)\n" +
				"Error:\n\(dumpResult.standardError)\n" +
				"Exit status: \(dumpResult.status)\n")
			return
		}

		// Turn the ASTs into Kotlin files
		print("\t* Transpiling files...")
		let bootstrapFolderName = "Bootstrap"
		let bootstrappedFiles = [
			"StandardLibrary",
			"PrintableAsTree",
			"SwiftAST",
			"ASTDumpDecoder",
			"Extensions",
			"Utilities", ]
		let bootstrappedFilesPaths = bootstrappedFiles.map { bootstrapFolderName + "/" + $0 }
		if Utilities.needsToUpdateFiles(
			bootstrappedFiles,
			in: bootstrapFolderName,
			from: .swiftASTDump,
			to: .kt)
		{
			do {
				try Compiler.generateKotlinCode(
					forFilesAt: bootstrappedFilesPaths, outputFolder: bootstrapFolderName)
			}
			catch let error {
				XCTFail("Failed to transpile bootstrap files.\n\(error)")
			}
		}

		// Compile the Kotlin version of the transpiler
		print("\t* Compiling Kotlin files...")
		let compilationCommand = [
			Compiler.kotlinCompilerPath,
			"-include-runtime", "-d", "kotlin.jar",
			"PrintableAsTree.kt", "PrintableAsTreeTest.kt",
			"SwiftAST.kt",
			"ASTDumpDecoder.kt", "ASTDumpDecoderTest.kt",
			"Extensions.kt", "ExtensionsTest.kt",
			"Utilities.kt", "UtilitiesTest.kt",
			"KotlinTests.kt", "StandardLibrary.kt", "main.kt", ]
		guard let compilationResult =
			Shell.runShellCommand(compilationCommand, fromFolder: "Bootstrap") else
		{
			XCTFail("Timed out.")
			return
		}
		guard compilationResult.status == 0 else {
			XCTFail("Failed to compile Kotlin bootstrap tests.\n" +
				"Output:\n\(compilationResult.standardOutput)\n" +
				"Error:\n\(compilationResult.standardError)\n" +
				"Exit status: \(compilationResult.status)\n")
			return
		}

		// Run the Kotlin version's tests
		print("\t* Running Kotlin tests...")
		let runCommand = ["java", "-jar", "kotlin.jar", ]
		guard let runResult =
			Shell.runShellCommand(runCommand, fromFolder: "Bootstrap") else
		{
			XCTFail("Timed out.")
			return
		}
		guard runResult.standardError == "",
			runResult.status == 0 else
		{
			XCTFail("Failed to run Kotlin bootstrap tests.\n" +
				"Output:\n\(runResult.standardOutput)\n" +
				"Error:\n\(runResult.standardError)\n" +
				"Exit status: \(runResult.status)\n")
			return
		}

		let testMessages = runResult.standardOutput.split(separator: "\n")
		for testMessage in testMessages {
			if !testMessage.hasSuffix("All tests succeeded!") {
				XCTFail(String(testMessage))
			}
		}
	}

	static var allTests = [
		("test", test),
	]
}
