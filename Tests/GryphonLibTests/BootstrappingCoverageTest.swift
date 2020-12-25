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

/// ⚠️ Used *only* for measuring code coverage in Xcode. To run the actual bootstrapping tests,
/// call `./Scripts/runTests.sh -b` from the command line.
/// The `shouldMeasureTestCoverage` flag is set to `false` to avoid running this test accidentally.
/// If you want to run the test, set it to `true`, but don't commit the change.
class BootstrappingCoverageTest: XCTestCase {
	/// Tests to be run when using Swift on Linux
	static var allTests = [
		("test", test),
	]

	let shouldMeasureTestCoverage = false

	// MARK: - Tests
	func test() {
		guard shouldMeasureTestCoverage else {
			return
		}

		let arguments: List = [
			"--indentation=4",
			"-print-ASTs-on-error",
			"--continue-on-error",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/ASTDumpDecoder.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/AuxiliaryFileContents.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/Compiler.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/Driver.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/Extensions.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/GryphonAST.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/GryphonSwiftLibrary.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/KotlinTranslationResult.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/KotlinTranslator.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/LibraryTranspilationPass.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/PrintableAsTree.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/RubyScriptContents.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/SharedUtilities.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/SourceFile.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/SwiftAST.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/SwiftTranslator.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/TranspilationContext.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/TranspilationPass.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/AcceptanceTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ASTDumpDecoderTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/CompilerTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/DriverTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ExtensionsTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/IntegrationTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/KotlinTranslationResultTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/LibraryTranspilationTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ListTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MutableListTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MapTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/MutableMapTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/PrintableAsTreeTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/ShellTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/SourceFileTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/UtilitiesTest.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/SharedTestUtilities.swift",
			"--skip",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/Shell.swift",
			"Test Files/Bootstrap/gryphon-old/Sources/GryphonLib/Utilities.swift",
			"Test Files/Bootstrap/gryphon-old/Tests/GryphonLibTests/TestUtilities.swift",
			"Test Files/Bootstrap/gryphon-old/.gryphon/GryphonXCTest.swift", ]

		XCTAssertNoThrow(try Driver.run(withArguments: arguments))
	}
}
