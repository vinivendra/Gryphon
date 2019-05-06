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
	func testUnitTests() {
		do {
			guard !BootstrappingTest.hasError else {
				XCTFail("Error during setup")
				return
			}

			guard let runOutput = try Compiler.runCompiledProgram(
				fromFolder: "Bootstrap",
				withArguments: ["-test"]) else
			{
				XCTFail("Error running transpiled transpiler. It's possible a command timed out.")
				return
			}

			let testMessages = runOutput.standardOutput.split(separator: "\n")
			XCTAssertEqual(testMessages.count, 4)
			for testMessage in testMessages {
				if !testMessage.hasSuffix("All tests succeeded!") {
					XCTFail(String(testMessage))
				}
			}
		}
		catch let error {
			XCTFail(error.localizedDescription)
		}
	}

	func testASTDumpDecoderOutput() {
		guard !BootstrappingTest.hasError else {
			XCTFail("Error during setup")
			return
		}

		let tests = TestUtils.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtils.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let kotlinArguments: ArrayClass = ["-emit-swiftAST", testFilePath]
				// FIXME: This would be ideal, but it's timing out
//				guard let runOutput = runTranspiledGryphon(withArguments: kotlinArguments) else {
//					XCTFail("Error running transpiled transpiler. " +
//						"It's possible a command timed out.\nRun result: \(runResult)")
//					return
//				}
//				let transpiledSwiftAST = runOutput.standardOutput

				let swiftASTFilePath = Utilities.changeExtension(of: testFilePath, to: .swiftAST)
				let transpiledSwiftAST = try Utilities.readFile(swiftASTFilePath)

				// Get Swift results
				let swiftArguments = kotlinArguments + ["-q", "-Q"]
				let driverResult = try Driver.run(withArguments: swiftArguments)
				guard let resultArray = driverResult as? ArrayClass<Any?>,
					let swiftASTs = resultArray.as(ArrayClass<SwiftAST>.self),
					let originalSwiftAST = swiftASTs.first else
				{
					XCTFail("Error generating SwiftASTs.\n" +
						"Driver result: \(driverResult ?? "nil")")
					return
				}

				// Compare results
				XCTAssert(
					transpiledSwiftAST == originalSwiftAST.description,
					"Test \(testName): failed to produce expected result. Diff:" +
						TestUtils.diff(transpiledSwiftAST, originalSwiftAST.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	func testSwiftTranslatorOutput() {
		guard !BootstrappingTest.hasError else {
			XCTFail("Error during setup")
			return
		}

		let tests = TestUtils.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtils.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let kotlinArguments: ArrayClass = ["-emit-rawAST", testFilePath]
				// FIXME: This would be ideal, but it's timing out
//				guard let runOutput = runTranspiledGryphon(withArguments: kotlinArguments) else {
//					XCTFail("Error running transpiled transpiler. " +
//						"It's possible a command timed out.\nRun result: \(runResult)")
//					return
//				}
//				let transpiledSwiftAST = runOutput.standardOutput

				let rawASTFilePath = Utilities.changeExtension(of: testFilePath, to: .gryphonASTRaw)
				let transpiledRawAST = try Utilities.readFile(rawASTFilePath)

				// Get Swift results
				let swiftArguments = kotlinArguments + ["-q", "-Q"]
				let driverResult = try Driver.run(withArguments: swiftArguments)
				guard let resultArray = driverResult as? ArrayClass<Any?>,
					let swiftASTs = resultArray.as(ArrayClass<SwiftAST>.self),
					let originalSwiftAST = swiftASTs.first else
				{
					XCTFail("Error generating SwiftASTs.\n" +
						"Driver result: \(driverResult ?? "nil")")
					return
				}

				// Compare results
				XCTAssert(
					transpiledRawAST == originalSwiftAST.description,
					"Test \(testName): failed to produce expected result. Diff:" +
						TestUtils.diff(transpiledRawAST, originalSwiftAST.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	override static func setUp() {
		print("* Updating bootstrap files...")

		defer {
			if Compiler.hasErrorsOrWarnings() {
				hasError = true
			}
			Compiler.printErrorsAndWarnings()
		}

		// Transpile the transpiler
		let outputFileMap = OutputFileMap("output-file-map.json")

		// Dump the ASTs
		if Utilities.needsToUpdateFiles(
			in: "Sources/GryphonLib",
			from: .swift,
			to: .swiftASTDump,
			outputFileMap: outputFileMap)
		{
			print("* Dumping the ASTs...")
			let dumpCommand = ["perl", "dumpTranspilerAST.pl" ]
			guard let dumpResult = Shell.runShellCommand(dumpCommand) else {
				hasError = true
				print("Timed out.")
				return
			}
			guard dumpResult.status == 0 else {
				hasError = true
				print("Failed to dump ASTs.\n" +
					"Output:\n\(dumpResult.standardOutput)\n" +
					"Error:\n\(dumpResult.standardError)\n" +
					"Exit status: \(dumpResult.status)\n")
				return
			}
		}

		let supportedFileNames = [
			"StandardLibrary",
			"PrintableAsTree",
			"SwiftAST",
			"SwiftTranslator",
			"GryphonAST",
			"ASTDumpDecoder",
			"Compiler",
			"OutputFileMap",
			"SourceFile",
			"Driver",
			"Extensions",
			"Utilities",
		]
		let supportedFilePaths = supportedFileNames.map { "Sources/GryphonLib/\($0).swift" }

		// Transpile the transpiler
		if Utilities.needsToUpdateFiles(
			supportedFileNames,
			in: "Sources/GryphonLib",
			from: .swift,
			to: .kt,
			outputFileMap: outputFileMap)
		{
			print("* Transpiling to kotlin...")
			let inputFiles: ArrayClass = supportedFilePaths + [
				"Bootstrap/PrintableAsTreeTest.kt",
				"Bootstrap/ASTDumpDecoderTest.kt",
				"Bootstrap/ExtensionsTest.kt",
				"Bootstrap/UtilitiesTest.kt",
				"Bootstrap/KotlinTests.kt",
				"Bootstrap/main.kt",
			]

			let arguments: ArrayClass<String> = [
				"build",
				"-output-file-map=output-file-map.json",
				"-indentation=\"    \"",
				] + inputFiles

			let driverResult: Any?
			do {
				driverResult = try Driver.run(withArguments: arguments)
			}
			catch let error {
				hasError = true
				print("Error running driver.\n\(error)")
				return
			}

			guard let compilationResult = driverResult as? Shell.CommandOutput else {
				hasError = true
				print("Error running driver. It's possible a command timed out.\n" +
					"Driver result: \(driverResult ?? "nil")")
				return
			}

			guard compilationResult.status == 0 else {
				hasError = true
				print("Failed to run Kotlin bootstrap tests.\n" +
					"Output:\n\(compilationResult.standardOutput)\n" +
					"Error:\n\(compilationResult.standardError)\n" +
					"Exit status: \(compilationResult.status)\n")
				return
			}
		}

		print("* Done.")
	}

	static var hasError = false

	static var allTests = [
		("test", testUnitTests),
	]
}
