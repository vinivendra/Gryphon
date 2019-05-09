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
				let kotlinArguments: ArrayClass = ["-emit-rawAST", "-no-main-file", testFilePath]
				let rawASTFilePath = Utilities.changeExtension(of: testFilePath, to: .gryphonASTRaw)
				let transpiledRawAST = try Utilities.readFile(rawASTFilePath)

				// Get Swift results
				let swiftArguments = kotlinArguments + ["-q", "-Q"]
				let driverResult = try Driver.run(withArguments: swiftArguments)
				guard let resultArray = driverResult as? ArrayClass<Any?>,
					let rawASTs = resultArray.as(ArrayClass<GryphonAST>.self),
					let originalRawAST = rawASTs.first else
				{
					XCTFail("Error generating raw ASTs.\n" +
						"Driver result: \(driverResult ?? "nil")")
					return
				}

				// Compare results
				XCTAssert(
					transpiledRawAST == originalRawAST.description,
					"Test \(testName): failed to produce expected result. Diff:" +
						TestUtils.diff(transpiledRawAST, originalRawAST.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	func testTranspilationPassOutput() {
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
				let kotlinArguments: ArrayClass = ["-emit-AST", "-no-main-file", testFilePath]
				let astFilePath = Utilities.changeExtension(of: testFilePath, to: .gryphonAST)
				let transpiledAST = try Utilities.readFile(astFilePath)

				// Get Swift results
				let swiftArguments = kotlinArguments + ["-q", "-Q"]
				let driverResult = try Driver.run(withArguments: swiftArguments)
				guard let resultArray = driverResult as? ArrayClass<Any?>,
					let asts = resultArray.as(ArrayClass<GryphonAST>.self),
					let originalAST = asts.first else
				{
					XCTFail("Error generating passed ASTs.\n" +
						"Driver result: \(driverResult ?? "nil")")
					return
				}

				// Compare results
				XCTAssert(
					transpiledAST == originalAST.description,
					"Test \(testName): failed to produce expected result. Diff:" +
						TestUtils.diff(transpiledAST, originalAST.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	override static func setUp() {
		let swiftFiles = Utilities.getFiles(
			inDirectory: "Sources/GryphonLib", withExtension: .swift)

		let astDumpFiles = Utilities.getFiles(
			inDirectory: "Test Files", withExtension: .swiftAST)
		let rawASTFiles = Utilities.getFiles(
			inDirectory: "Test Files", withExtension: .gryphonASTRaw)

		if Utilities.files(swiftFiles, wereModifiedLaterThan: astDumpFiles) ||
			Utilities.files(swiftFiles, wereModifiedLaterThan: rawASTFiles)
		{
			print("🚨 Bootstrap test files are out of date.\n" +
				"Please run `updateBootstrapTestFiles.sh`.")
			hasError = true
		}
	}

	static var hasError = false

	static var allTests = [
		("test", testUnitTests),
	]
}
