//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
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

import Foundation

class TestError: Error { }

class TestUtilities {
	// MARK: - Diffs
	static let relativeTestFilesPath = "Test files"
	static let relativeTestCasesPath = "\(relativeTestFilesPath)/Test cases"
	static let relativeBootstrapPath = "\(relativeTestFilesPath)/Bootstrap"
	static let testCasesPath = Utilities.getCurrentFolder() + "/\(relativeTestCasesPath)/"
	static let bootstrapPath = Utilities.getCurrentFolder() + "/\(relativeBootstrapPath)/"

	static func diff(_ string1: String, _ string2: String) -> String {
		do {
			let diffResult = try withTemporaryFile(fileName: "file1.txt", contents: string1)
			{ file1Path in
				try withTemporaryFile(fileName: "file2.txt", contents: string2)
				{ file2Path in
					TestUtilities.diffFiles(file1Path, file2Path)
				}
			}

			if let diffResult = diffResult {
				return diffResult
			}
			else {
				return "Diff timed out. Printing full result.\n" +
					"\n===\nDiff string 1:\n\n\(string1)===\n" +
					"\n===\nDiff string 2:\n\n\(string2)===\n"
			}
		}
		catch {
			return "Diff timed out. Printing full result.\n" +
				"\n===\nDiff string 1:\n\n\(string1)===\n" +
				"\n===\nDiff string 2:\n\n\(string2)===\n"
		}
	}

	static func diffFiles(_ file1Path: String, _ file2Path: String) -> String? {
		let command: List = ["diff", file1Path, file2Path]
		let commandResult = Shell.runShellCommand(command)
		return "\n\n===\n\(commandResult.standardOutput)===\n"
	}

	static func withTemporaryFile<T>(
		fileName: String,
		contents: String,
		closure: (String) throws -> T)
	throws -> T
	{
		let temporaryDirectory = ".tmp"

		let filePath = try Utilities.createFile(
			named: fileName,
			inDirectory: temporaryDirectory,
			containing: contents)
		return try closure(filePath)
	}

	static func changeCurrentDirectoryPath(_ newPath: String) {
		let success = FileManager.default.changeCurrentDirectoryPath(newPath)
		assert(success)
	}

	public static let kotlinBuildFolder =
		"\(SupportingFile.gryphonBuildFolder)/kotlinBuild-\(OS.systemIdentifier)"

	// MARK: - Test cases
	static let testCases: List = [
		"access",
		"assignments",
		"classes",
		"closures",
		"enums",
		"extensions",
		"functionCalls",
		"generics",
		"gryphonLibraries",
		"ifStatement",
		"inits",
		"kotlinLiterals",
		"logicOperators",
		"misc",
		"numericLiterals",
		"openAndFinal",
		"openAndFinal-default-final",
		"operators",
		"protocols",
		"standardLibrary",
		"strings",
		"structs",
		"subscripts",
		"switches",
	]

	/// The same tests in `testCases`, sorted so that recently modified tests come first.
	static let sortedTests = SortedList(testCases) { testNameA, testNameB in
		let testPathA = (TestUtilities.testCasesPath + testNameA).withExtension(.kt)
		let testPathB = (TestUtilities.testCasesPath + testNameB).withExtension(.kt)
		return Utilities.file(testPathA, wasModifiedLaterThan: testPathB)
	}
}
