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

class DriverTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("testOutputs", testOutputs),
		("testGenerateGryphonLibraries", testGenerateGryphonLibraries),
		("testUsageString", testUsageString),
		("testNoMainFile", testNoMainFile),
		("testContinueOnErrors", testContinueOnErrors),
		("testIndentation", testIndentation),
	]

	override static func setUp() {
		do {
			try TestUtilities.updateASTsForTestCases()
		}
		catch let error {
			print(error)
			fatalError("Failed to update test files.")
		}
	}

	// MARK: - Tests
	func testOutputs() {
		let oldOutputFunction = Compiler.outputFunction
		let oldErrorFunction = Compiler.logError

		var compilerOutput = ""
		var compilerError = ""
		Compiler.outputFunction = { (contents: Any, terminator: String) -> () in
				compilerOutput = compilerOutput + "\(contents)" + terminator
			}
		Compiler.logError = { (contents: Any) -> () in
				compilerError = compilerError + "\(contents)"
			}

		do {
			try Driver.run(withArguments: ["\(TestUtilities.relativeTestFilesPath)/test.swift"])
			XCTAssert(!compilerOutput.isEmpty)

			compilerOutput = ""
			try Driver.run(withArguments: ["\(TestUtilities.testCasesPath)outputs.swift"])
			XCTAssert(compilerOutput.isEmpty)

			compilerOutput = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)outputs.swift",
							 "--write-to-console"])
			XCTAssert(!compilerOutput.isEmpty)

			// Check if --quiet mutes outputs and warnings
			compilerOutput = ""
			compilerError = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)warnings.swift",
							 "--write-to-console",
							 "--quiet"])
			XCTAssert(compilerOutput.isEmpty)
			XCTAssert(compilerError.isEmpty)

			// Check if --quiet does not mute errors
			compilerOutput = ""
			compilerError = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)errors.swift",
							 "--write-to-console",
							 "--quiet",
							 "--continue-on-error"])
			XCTAssert(compilerOutput.isEmpty)
			XCTAssert(!compilerError.isEmpty)
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		Compiler.outputFunction = oldOutputFunction
		Compiler.logError = oldErrorFunction
	}

	func testOutputsWithASTDumps() {
		let oldOutputFunction = Compiler.outputFunction
		let oldErrorFunction = Compiler.logError

		var compilerOutput = ""
		var compilerError = ""
		Compiler.outputFunction = { (contents: Any, terminator: String) -> () in
				compilerOutput = compilerOutput + "\(contents)" + terminator
			}
		Compiler.logError = { (contents: Any) -> () in
				compilerError = compilerError + "\(contents)"
			}

		do {
			try Driver.run(withArguments:
							["\(TestUtilities.relativeTestFilesPath)/test.swift",
							 "--legacyFrontend"])
			XCTAssert(!compilerOutput.isEmpty)

			compilerOutput = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)outputs.swift",
							 "--legacyFrontend"])
			XCTAssert(compilerOutput.isEmpty)

			compilerOutput = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)outputs.swift",
							 "--write-to-console",
							 "--legacyFrontend"])
			XCTAssert(!compilerOutput.isEmpty)

			// Check if --quiet mutes outputs and warnings
			compilerOutput = ""
			compilerError = ""
			try Driver.run(withArguments:
				["\(TestUtilities.testCasesPath)warnings.swift",
				 "--write-to-console",
				 "--quiet",
				 "--legacyFrontend"])
			XCTAssert(compilerOutput.isEmpty)
			XCTAssert(compilerError.isEmpty)

			// Check if --quiet does not mute errors
			compilerOutput = ""
			compilerError = ""
			try Driver.run(withArguments:
							["\(TestUtilities.testCasesPath)errors.swift",
							 "--write-to-console",
							 "--quiet",
							 "--continue-on-error",
							 "--legacyFrontend"])
			XCTAssert(compilerOutput.isEmpty)
			XCTAssert(!compilerError.isEmpty)
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		Compiler.outputFunction = oldOutputFunction
		Compiler.logError = oldErrorFunction
	}

	func testGenerateGryphonLibraries() {
		do {
			try Driver.run(withArguments: ["generate-libraries"])

			let originalSwiftLibraryContents = try Utilities.readFile(
				"Sources/GryphonLib/GryphonSwiftLibrary.swift")
			let generatedSwiftLibraryContents = try Utilities.readFile(
				SupportingFile.gryphonSwiftLibrary.relativePath)
			XCTAssert(
				originalSwiftLibraryContents == generatedSwiftLibraryContents,
					"The generated Swift library is different than the original one. " +
					"Printing diff ('<' means original, '>' means generated):" +
				TestUtilities.diff(originalSwiftLibraryContents, generatedSwiftLibraryContents))

			// The Kotlin library is generated with an extra comment and a `package` placeholder
			// statement that aren't in the library Gryphon uses internally.
			// This assumes the statement is followed by two newlines.
			let actualKotlinLibraryContents = try Utilities.readFile(
				TestUtilities.bootstrapPath + "GryphonKotlinLibrary.kt")
			let generatedKotlinLibraryContents = try Utilities.readFile(
				SupportingFile.gryphonKotlinLibrary.relativePath)
			let processedKotlinLibraryContents = String(generatedKotlinLibraryContents
				.drop(while: { $0 != "\n" }) // Drop the comment
				.dropFirst("\n".count)
				.drop(while: { $0 != "\n" }) // Drop the package statement
				.dropFirst("\n\n".count))
			XCTAssert(
				actualKotlinLibraryContents == processedKotlinLibraryContents,
					"The generated Kotlin library is different than the original one. " +
					"Printing diff ('<' means original, '>' means generated):" +
				TestUtilities.diff(actualKotlinLibraryContents, processedKotlinLibraryContents))

			Utilities.deleteFile(at: SupportingFile.gryphonSwiftLibrary.relativePath)
			Utilities.deleteFile(at: SupportingFile.gryphonKotlinLibrary.relativePath)
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	func testUsageString() {
		for argument in Driver.supportedArguments {
			XCTAssert(
				Driver.usageString.contains(argument),
				"No help information for the argument \(argument)")
		}

		for argument in Driver.supportedArgumentsWithParameters {
			XCTAssert(
				Driver.usageString.contains(argument),
				"No help information for the argument \(argument)")
		}
	}

	func testNoMainFile() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "ifStatement.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])
			let resultArray1 = driverResult1 as? List<Any?>
			let kotlinTranslations1 = resultArray1?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation1 = kotlinTranslations1?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			let kotlinCode1 = kotlinTranslation1.kotlinCode

			XCTAssert(kotlinCode1.contains("fun main(args: Array<String>) {"))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--no-main-file",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])
			let resultArray2 = driverResult2 as? List<Any?>
			let kotlinTranslations2 = resultArray2?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation2 = kotlinTranslations2?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

			let kotlinCode2 = kotlinTranslation2.kotlinCode

			XCTAssertFalse(kotlinCode2.contains("fun main(args: Array<String>) {"))

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		XCTAssertFalse(Compiler.hasIssues())
		Compiler.printIssues()
	}

	func testContinueOnErrors() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "errors.swift"

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--continue-on-error",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])

			XCTAssert(Compiler.numberOfErrors == 2)

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--no-main-file",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])

			XCTFail("Expected Driver to throw an error.")
		}
		catch {
			// If the Driver threw an error then it's working correctly.
		}

		// Repeat the test using AST dumps
		do {
			let testCasePath = TestUtilities.testCasesPath + "errors.swift"

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--continue-on-error",
				 "--write-to-console",
				 "--quiet",
				 "--legacyFrontend",
				 testCasePath, ])

			XCTAssert(Compiler.numberOfErrors == 2)

			//
			Compiler.clearIssues()

			_ = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--no-main-file",
				 "--write-to-console",
				 "--quiet",
				 "--legacyFrontend",
				 testCasePath, ])

			XCTFail("Expected Driver to throw an error.")
		}
		catch {
			// If the Driver threw an error then it's working correctly.
		}

		Compiler.clearIssues()
	}

	func testIndentation() {
		do {
			let testCasePath = TestUtilities.testCasesPath + "ifStatement.swift"

			//
			let driverResult1 = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=t",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])
			let resultArray1 = driverResult1 as? List<Any?>
			let kotlinTranslations1 = resultArray1?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation1 = kotlinTranslations1?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult1 ?? "nil")")
				return
			}

			let kotlinCode1 = kotlinTranslation1.kotlinCode

			XCTAssert(kotlinCode1.contains("\t"))
			XCTAssertFalse(kotlinCode1.contains("    "))

			//
			let driverResult2 = try Driver.run(withArguments:
				["-skip-AST-dumps",
				 "-emit-kotlin",
				 "--indentation=4",
				 "--write-to-console",
				 "--quiet",
				 testCasePath, ])
			let resultArray2 = driverResult2 as? List<Any?>
			let kotlinTranslations2 = resultArray2?.as(List<Driver.KotlinTranslation>.self)

			guard let kotlinTranslation2 = kotlinTranslations2?.first else {
				XCTFail("Error generating Kotlin code.\n" +
					"Driver result: \(driverResult2 ?? "nil")")
				return
			}

			let kotlinCode2 = kotlinTranslation2.kotlinCode

			XCTAssert(kotlinCode2.contains("    "))
			XCTAssertFalse(kotlinCode2.contains("\t"))

		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}

		XCTAssertFalse(Compiler.hasIssues())
		Compiler.printIssues()
	}
}
