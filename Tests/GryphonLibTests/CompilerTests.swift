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

class CompilerTest: XCTestCase {
	struct MyError: Error { }

	func testKotlinCompiler() {
		XCTAssert(Utilities.fileExists(at: Compiler.kotlinCompilerPath))
	}

	func testErrorHandling() {
		do {
			Compiler.shouldStopAtFirstError = false

			//
			try Compiler.handleError(MyError())

			XCTAssert(Compiler.hasErrorsOrWarnings())
			XCTAssertFalse(Compiler.errors.isEmpty)
			XCTAssert(Compiler.warnings.isEmpty)

			Compiler.clearErrorsAndWarnings()

			XCTAssertFalse(Compiler.hasErrorsOrWarnings())
			XCTAssert(Compiler.errors.isEmpty)
			XCTAssert(Compiler.warnings.isEmpty)

			//
			Compiler.handleWarning(message: "", sourceFile: nil, sourceFileRange: nil)

			XCTAssert(Compiler.hasErrorsOrWarnings())
			XCTAssert(Compiler.errors.isEmpty)
			XCTAssertFalse(Compiler.warnings.isEmpty)

			Compiler.clearErrorsAndWarnings()

			XCTAssertFalse(Compiler.hasErrorsOrWarnings())
			XCTAssert(Compiler.errors.isEmpty)
			XCTAssert(Compiler.warnings.isEmpty)
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

		//
		let errorMessage = Compiler.createErrorOrWarningMessage(
			message: "My error message",
			details: "Some details",
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: true)

		let errorMessageWithRelativePath =
			errorMessage.dropFirst(Utilities.getCurrentFolder().count + 1)

		XCTAssertEqual(
			errorMessageWithRelativePath,
			"""
			path/to/file.swift:1:5: error: My error message
			let x: Int = 0
			    ^
			Some details
			""")

		//
		let warningMessage = Compiler.createErrorOrWarningMessage(
			message: "My warning message",
			details: "Some details",
			sourceFile: sourceFile,
			sourceFileRange: sourceFileRange,
			isError: false)

		let warningMessageWithRelativePath =
			warningMessage.dropFirst(Utilities.getCurrentFolder().count + 1)

		XCTAssertEqual(
			warningMessageWithRelativePath,
			"""
			path/to/file.swift:1:5: warning: My warning message
			let x: Int = 0
			    ^
			Some details
			""")
    }
}
