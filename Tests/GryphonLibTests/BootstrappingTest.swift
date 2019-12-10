//
// Copyright 2018 Vinícius Jorge Vendramini
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
				inFolder: "Bootstrap",
				withArguments: ["-test"]) else
			{
				XCTFail("Error running transpiled transpiler. It's possible a command timed out.")
				return
			}

			let testMessages = runOutput.standardOutput.split(separator: "\n")
			XCTAssertEqual(testMessages.count, 7)

			var testsFailed = false
			for testMessage in testMessages {
				if !testMessage.hasSuffix("All tests succeeded!") {
					XCTFail(String(testMessage))
					testsFailed = true
				}
			}

			if testsFailed {
				print(runOutput.standardError)
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

		let tests = TestUtilities.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtilities.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let swiftASTFilePath = BootstrappingTest.getBootstrapOutputFilePath(
					forTest: testName,
					withExtension: .swiftAST)
				let transpiledSwiftAST = try Utilities.readFile(swiftASTFilePath)

				// Get Swift results
				let driverResult = try Driver.run(withArguments:
					["-skipASTDumps",
					 "-emit-swiftAST",
					 "-indentation=t",
					 "-q", "-Q",
					 testFilePath, ])
				guard let resultArray = driverResult as? MutableArray<Any?>,
					let swiftASTs = resultArray.as(MutableArray<SwiftAST>.self),
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
						TestUtilities.diff(transpiledSwiftAST, originalSwiftAST.description))
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

		let tests = TestUtilities.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtilities.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let rawASTFilePath = BootstrappingTest.getBootstrapOutputFilePath(
					forTest: testName,
					withExtension: .gryphonASTRaw)
				let transpiledRawAST = try Utilities.readFile(rawASTFilePath)

				// Get Swift results
				let driverResult = try Driver.run(withArguments:
					["-skipASTDumps",
					 "-emit-rawAST",
					 "-indentation=t",
					 "-q", "-Q",
					 testFilePath, ])
				guard let resultArray = driverResult as? MutableArray<Any?>,
					let rawASTs = resultArray.as(MutableArray<GryphonAST>.self),
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
						TestUtilities.diff(transpiledRawAST, originalRawAST.description))
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

		let tests = TestUtilities.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtilities.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let astFilePath = BootstrappingTest.getBootstrapOutputFilePath(
					forTest: testName,
					withExtension: .gryphonAST)
				let transpiledAST = try Utilities.readFile(astFilePath)

				// Get Swift results
				let driverResult = try Driver.run(withArguments:
					["-skipASTDumps",
					 "-emit-AST",
					 "-indentation=t",
					 "-q", "-Q",
					 testFilePath, ])
				guard let resultArray = driverResult as? MutableArray<Any?>,
					let asts = resultArray.as(MutableArray<GryphonAST>.self),
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
						TestUtilities.diff(transpiledAST, originalAST.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	func testKotlinTranslatorOutput() {
		guard !BootstrappingTest.hasError else {
			XCTFail("Error during setup")
			return
		}

		let tests = TestUtilities.testCasesForAllTests

		for testName in tests {
			print("- Testing \(testName)...")

			do {
				let testFilePath = TestUtilities.testFilesPath + testName + ".swift"

				// Get Kotlin results
				let testOutputFilePath = BootstrappingTest.getBootstrapOutputFilePath(
					forTest: testName,
					withExtension: .kt)
				let transpiledKotlinCode = try Utilities.readFile(testOutputFilePath)

				// Get Swift results
				let driverResult = try Driver.run(withArguments:
					["-skipASTDumps",
					 "-emit-kotlin",
					 "-indentation=t",
					 "-q", "-Q",
					 testFilePath, ])
				guard let resultArray = driverResult as? MutableArray<Any?>,
					let kotlinCodes = resultArray
						.as(MutableArray<Driver.KotlinTranslation>.self)?
						.map({ $0.kotlinCode }),
					let originalKotlinCode = kotlinCodes.first else
				{
					XCTFail("Error generating passed ASTs.\n" +
						"Driver result: \(driverResult ?? "nil")")
					return
				}

				// Compare results
				XCTAssert(
					transpiledKotlinCode == originalKotlinCode.description,
					"Test \(testName): failed to produce expected result. Diff:" +
						TestUtilities.diff(transpiledKotlinCode, originalKotlinCode.description))
			}
			catch let error {
				XCTFail("🚨 Test failed with error:\n\(error)")
			}
		}

		XCTAssertFalse(Compiler.hasErrorsOrWarnings())
		Compiler.printErrorsAndWarnings()
	}

	static func getBootstrapOutputFilePath(
		forTest testName: String,
		withExtension fileExtension: FileExtension)
		-> String
	{
		return bootstrapOutputsFolder + "/" + testName + "." + fileExtension.rawValue
	}

	override static func setUp() {
		let swiftFiles = Utilities.getFiles(
			inDirectory: "Sources/GryphonLib", withExtension: .swift)

		let swiftASTFiles = Utilities.getFiles(
			inDirectory: bootstrapOutputsFolder, withExtension: .swiftAST)
		let rawASTFiles = Utilities.getFiles(
			inDirectory: bootstrapOutputsFolder, withExtension: .gryphonASTRaw)
		let astFiles = Utilities.getFiles(
			inDirectory: bootstrapOutputsFolder, withExtension: .gryphonAST)
		let kotlinFiles = Utilities.getFiles(
			inDirectory: bootstrapOutputsFolder, withExtension: .kt)

		if Utilities.files(swiftFiles, wereModifiedLaterThan: swiftASTFiles) ||
			Utilities.files(swiftFiles, wereModifiedLaterThan: rawASTFiles) ||
			Utilities.files(swiftFiles, wereModifiedLaterThan: astFiles) ||
			Utilities.files(swiftFiles, wereModifiedLaterThan: kotlinFiles)
		{
			print("🚨 Bootstrap test files are out of date." +
				"Please run `bootstrapGryphon.sh` and then `prepareForBootstrapTests.sh`.")
			hasError = true
		}
	}

	static let bootstrapOutputsFolder = "Test Files/Bootstrap Outputs"

	static var hasError = false

	static var allTests = [
		("testUnitTests", testUnitTests),
		("testASTDumpDecoderOutput", testASTDumpDecoderOutput),
		("testSwiftTranslatorOutput", testSwiftTranslatorOutput),
		("testTranspilationPassOutput", testTranspilationPassOutput),
		("testKotlinTranslatorOutput", testKotlinTranslatorOutput),
	]
}
