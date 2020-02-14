//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Bootstrap/SourceFileTest.kt

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class SourceFileTest: XCTestCase {
	// gryphon insert: constructor(): super() { }

	public func getClassName() -> String { // gryphon annotation: override
		return "SourceFileTest"
	}

	/// Tests to be run by the translated Kotlin version.
	public func runAllTests() { // gryphon annotation: override
		testGetCommentFromLine()
		testGetTranslationCommentFromLine()
	}

	/// Tests to be run when using Swift on Linux
	static var allTests = [ // gryphon ignore
		("testGetCommentFromLine", testGetCommentFromLine),
		("testGetTranslationCommentFromLine", testGetTranslationCommentFromLine),
	]

	// MARK: - Tests
	func testGetCommentFromLine() {
		let sourceFileContents = """
			let x: Int = 0 // gryphon ignore
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
		// TODO: add tests for insert comments once they are fixed on multiline strings
		let sourceFileContents = """
			let x: Int = 0 // gryphon ignore
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
