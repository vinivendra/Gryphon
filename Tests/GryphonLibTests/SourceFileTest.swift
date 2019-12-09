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

// gryphon output: Bootstrap/SourceFileTest.kt

#if !IS_DUMPING_ASTS
@testable import GryphonLib
import XCTest
#endif

class SourceFileTest: XCTestCase {
	// declaration: constructor(): super() { }

	public func getClassName() -> String { // annotation: override
		return "SourceFileTest"
	}

	override public func runAllTests() { // annotation: override
		testGetCommentFromLine()
		testGetKeyedCommentFromLine()
		super.runAllTests()
	}

	static var allTests = [ // kotlin: ignore
		("testGetCommentFromLine", testGetCommentFromLine),
		("testGetKeyedCommentFromLine", testGetKeyedCommentFromLine),
	]

	// MARK: - Tests
	func testGetCommentFromLine() {
		let sourceFileContents = """
			let x: Int = 0 // kotlin: ignore
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

	func testGetKeyedCommentFromLine() {
		let sourceFileContents = """
			let x: Int = 0 // kotlin: ignore
			// blabla
			let x: Int = 0

			"""
		let sourceFile = SourceFile(path: "", contents: sourceFileContents)
		let comment = sourceFile.getKeyedCommentFromLine(1)

		XCTAssertEqual(comment?.value, "ignore")
		XCTAssertEqual(comment?.key, .kotlin)
		XCTAssertNil(sourceFile.getKeyedCommentFromLine(2)) // Common comment
		XCTAssertNil(sourceFile.getKeyedCommentFromLine(3)) // No comment
		XCTAssertNil(sourceFile.getKeyedCommentFromLine(10)) // Out of range
		XCTAssertNil(sourceFile.getKeyedCommentFromLine(-1)) // Negative number
	}
}
