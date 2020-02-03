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

// gryphon output: Bootstrap/TestUtilities.kt

import Foundation

#if !IS_DUMPING_ASTS
@testable import GryphonLib
import XCTest
#endif

class TestError: Error {
	// declaration: constructor(): super() { }
}

class TestUtilities {
	// MARK: - Diffs
	static let testFilesPath: String = Utilities.getCurrentFolder() + "/Test Files/"

	static func diff(_ string1: String, _ string2: String) -> String {
		return withTemporaryFile(fileName: "file1.txt", contents: string1) { file1Path in
			withTemporaryFile(fileName: "file2.txt", contents: string2) { file2Path in
				TestUtilities.diffFiles(file1Path, file2Path)
			}
		}
	}

	static func diffFiles(_ file1Path: String, _ file2Path: String) -> String {
		let command: MutableList = ["diff", file1Path, file2Path]
		let commandResult = Shell.runShellCommand(command)
		if let commandResult = commandResult {
			return "\n\n===\n\(commandResult.standardOutput)===\n"
		}
		else {
			return " timed out."
		}
	}

	static func withTemporaryFile<T>(
		fileName: String,
		contents: String,
		closure: (String) throws -> T)
		rethrows -> T
	{
		let temporaryDirectory = ".tmp"

		let filePath = Utilities.createFile(
			named: fileName,
			inDirectory: temporaryDirectory,
			containing: contents)
		return try closure(filePath)
	}

	// MARK: - Test cases
	static let testCasesForAcceptanceTest: List<String> = [
		"arrays",
		"assignments",
		"bhaskara",
		"classes",
		"closures",
		"dictionaries",
		"extensions",
		"functionCalls",
		"ifStatement",
		"inits",
		"kotlinLiterals",
		"logicOperators",
		"misc",
		"numericLiterals",
		"operators",
		"standardLibrary",
		"structs",
		"switches",
	]
	static let testCasesForAllTests = testCasesForAcceptanceTest + List<String>([
		"enums",
		"strings",
	])
	static let testCasesForTranspilationPassTest = testCasesForAllTests + List<String>([
		"warnings",
	])
	static let allTestCases = testCasesForTranspilationPassTest
}

// MARK: - XCTestCase stubs
#if !IS_DUMPING_ASTS
/// This extension is needed so that classes that override this method can call `super`, which is
/// important for the Kotlin tests.
extension XCTestCase {
	public func runAllTests() { }
}
#endif
