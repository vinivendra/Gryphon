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
		guard let runOutput = runTranspiledGryphon(withArguments: ["-test"]) else {
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

	func runTranspiledGryphon(withArguments arguments: [String]) -> Shell.CommandOutput? {
		let runResult: Compiler.KotlinCompilationResult
		do {
			runResult =
				try Compiler.runCompiledProgram(fromFolder: "Bootstrap", withArguments: arguments)
		}
		catch let error {
			XCTFail("Error running driver.\n\(error)")
			return nil
		}

		guard case let .success(commandOutput: runOutput) = runResult else
		{
			XCTFail("Error running transpiled transpiler. It's possible a command timed out.\n" +
				"Run result: \(runResult)")
			return nil
		}

		return runOutput
	}

	override static func setUp() {
		// Transpile the transpiler
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

		// Transpile the transpiler
		let inputFiles: ArrayReference = [
			"Sources/GryphonLib/StandardLibrary.swift",
			"Sources/GryphonLib/PrintableAsTree.swift",
			"Sources/GryphonLib/SwiftAST.swift",
			"Sources/GryphonLib/ASTDumpDecoder.swift",
			"Sources/GryphonLib/Compiler.swift",
			"Sources/GryphonLib/OutputFileMap.swift",
			"Sources/GryphonLib/SourceFile.swift",
			"Sources/GryphonLib/Driver.swift",
			"Sources/GryphonLib/Extensions.swift",
			"Sources/GryphonLib/Utilities.swift",
			"Bootstrap/PrintableAsTreeTest.kt",
			"Bootstrap/ASTDumpDecoderTest.kt",
			"Bootstrap/ExtensionsTest.kt",
			"Bootstrap/UtilitiesTest.kt",
			"Bootstrap/KotlinTests.kt",
			"Bootstrap/main.kt",
		]

		let arguments: ArrayReference =
			["build", "-output-file-map=output-file-map.json"] + inputFiles

		let driverResult: Any?
		do {
			driverResult = try Driver.run(withArguments: arguments)
		}
		catch let error {
			XCTFail("Error running driver.\n\(error)")
			return
		}

		guard let compilationResult = driverResult as? Compiler.KotlinCompilationResult,
			case let .success(commandOutput: commandOutput) = compilationResult else
		{
			XCTFail("Error running driver. It's possible a command timed out.\n" +
				"Driver result: \(driverResult ?? "nil")")
			return
		}

		guard commandOutput.status == 0 else {
			XCTFail("Failed to run Kotlin bootstrap tests.\n" +
				"Output:\n\(commandOutput.standardOutput)\n" +
				"Error:\n\(commandOutput.standardError)\n" +
				"Exit status: \(commandOutput.status)\n")
			return
		}
	}

	static var allTests = [
		("test", test),
	]
}
