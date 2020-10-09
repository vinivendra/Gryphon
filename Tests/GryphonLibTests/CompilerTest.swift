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

// gryphon output: Bootstrap/CompilerTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class CompilerTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	// gryphon annotation: override
	public func getClassName() -> String {
		return "CompilerTest"
	}

	/// Tests to be run by the translated Kotlin version.
	// gryphon annotation: override
	public func runAllTests() {
		testErrorHandling()
		testErrorMessages()
	}

	/// Tests to be run when using Swift on Linux
	// gryphon ignore
	static var allTests = [
		("testErrorHandling", testErrorHandling),
		("testErrorMessages", testErrorMessages),
	]

	// MARK: - Tests
	func testErrorHandling() {
		do {
			Compiler.shouldStopAtFirstError = false

			//
			try Compiler.handleError(message: "", sourceFile: nil, sourceFileRange: nil)

			XCTAssert(Compiler.hasIssues())
			XCTAssertFalse(Compiler.numberOfErrors == 0)
			XCTAssert(Compiler.numberOfWarnings == 0)

			Compiler.clearIssues()

			XCTAssertFalse(Compiler.hasIssues())
			XCTAssert(Compiler.numberOfErrors == 0)
			XCTAssert(Compiler.numberOfWarnings == 0)

			//
			Compiler.handleWarning(message: "", sourceFile: nil, sourceFileRange: nil)

			XCTAssert(Compiler.hasIssues())
			XCTAssert(Compiler.numberOfErrors == 0)
			XCTAssertFalse(Compiler.numberOfWarnings == 0)

			Compiler.clearIssues()

			XCTAssertFalse(Compiler.hasIssues())
			XCTAssert(Compiler.numberOfErrors == 0)
			XCTAssert(Compiler.numberOfWarnings == 0)
		}
		catch let error {
			XCTFail("🚨 Test failed with error:\n\(error)")
		}
	}

	func testErrorMessages() {
		let sourceFile = SourceFile(
			path: "path/to/file.swift",
			contents: "let x: Int = 0\n")
		let sourceFileRange = SourceFileRange(
			lineStart: 1,
			lineEnd: 1,
			columnStart: 5,
			columnEnd: 5)

		// Test error
		let errorMessage = CompilerIssue(
			message: "My error message",
			ast: nil,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: true).fullMessage

		let errorMessageWithRelativePath =
			errorMessage.dropFirst(Utilities.getCurrentFolder().count + 1)

		XCTAssertEqual(
			errorMessageWithRelativePath,
			"""
			path/to/file.swift:1:5: error: My error message
			let x: Int = 0
			    ^

			""")

		// Test warning
		let warningMessage = CompilerIssue(
			message: "My warning message",
			ast: nil,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: false).fullMessage

		let warningMessageWithRelativePath =
			warningMessage.dropFirst(Utilities.getCurrentFolder().count + 1)

		XCTAssertEqual(
			warningMessageWithRelativePath,
			"""
			path/to/file.swift:1:5: warning: My warning message
			let x: Int = 0
			    ^

			""")

		// Test issue with AST
		let oldShouldPrintASTs = CompilerIssue.shouldPrintASTs
		CompilerIssue.shouldPrintASTs = true

		let ast = PrintableTree("A", [PrintableTree("B")])
		let errorMessage2 = CompilerIssue(
			message: "My error message",
			ast: ast,
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: true).fullMessage

		let errorMessageWithAST =
			errorMessage2.dropFirst(Utilities.getCurrentFolder().count + 1)

		XCTAssertEqual(
			errorMessageWithAST,
			"""
			path/to/file.swift:1:5: error: My error message
			let x: Int = 0
			    ^
			Thrown when translating the following AST node:
			 A
			 └─ B

			""")

		CompilerIssue.shouldPrintASTs = oldShouldPrintASTs
    }
}
