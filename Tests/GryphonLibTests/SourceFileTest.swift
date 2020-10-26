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

// gryphon output: Test Files/Bootstrap/SourceFileTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class SourceFileTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	// gryphon annotation: override
	public func getClassName() -> String {
		return "SourceFileTest"
	}

	/// Tests to be run by the translated Kotlin version.
	// gryphon annotation: override
	public func runAllTests() {
		testGetCommentFromLine()
		testGetTranslationCommentFromLine()
	}

	/// Tests to be run when using Swift on Linux
	// gryphon ignore
	static var allTests = [
		("testGetCommentFromLine", testGetCommentFromLine),
		("testGetTranslationCommentFromLine", testGetTranslationCommentFromLine),
	]

	// MARK: - Tests
	func testGetCommentFromLine() {
		let sourceFileContents = """
			// gryphon ignore
			let x: Int = 0
			// blabla
			let x: Int = 0

			"""
		let sourceFile = SourceFile(path: "", contents: sourceFileContents)
		let comment = sourceFile.getCommentFromLine(2)

		XCTAssertEqual(comment?.contents, " blabla")
		XCTAssertEqual(comment?.range, SourceFileRange(
			lineStart: 2,
			lineEnd: 2,
			columnStart: 0,
			columnEnd: 9))
		XCTAssertNil(sourceFile.getCommentFromLine(1)) // Keyed comment
		XCTAssertNil(sourceFile.getCommentFromLine(3)) // No comment
		XCTAssertNil(sourceFile.getCommentFromLine(10)) // Out of range
		XCTAssertNil(sourceFile.getCommentFromLine(-1)) // Negative number
	}

	func testGetTranslationCommentFromLine() {
		// gryphon multiline
		let sourceFileContents = """
			// gryphon ignore
			let x: Int = 0
			// blabla
			let x: Int = 0

			"""
		let sourceFile = SourceFile(path: "", contents: sourceFileContents)
		let comment = sourceFile.getTranslationCommentFromLine(1)

		XCTAssertEqual(comment?.value, nil)
		XCTAssertEqual(comment?.key, .ignore)
		XCTAssertNil(sourceFile.getTranslationCommentFromLine(2)) // Common comment
		XCTAssertNil(sourceFile.getTranslationCommentFromLine(3)) // No comment
		XCTAssertNil(sourceFile.getTranslationCommentFromLine(10)) // Out of range
		XCTAssertNil(sourceFile.getTranslationCommentFromLine(-1)) // Negative number
	}
}
