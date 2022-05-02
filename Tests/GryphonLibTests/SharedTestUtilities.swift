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

// gryphon output: Test Files/Bootstrap/SharedTestUtilities.kt

// gryphon insert: import kotlin.system.*

import Foundation

#if !GRYPHON
@testable import GryphonLib
import XCTest
#endif

class TestError: Error {
	// gryphon insert: constructor(): super() { }
}

class TestUtilities {
	// MARK: - Diffs
	/// Tests always run using the Swift 5.5 AST Dump, since it's the latest Swift version that's compatible with this
	/// (old) Gryphon's AST Dump structure. From Swift 5.6 onward it'd be necessary to update this version to be
	/// compatible with the new AST Dump structure, which isn't worth it as it doesn't improve the quality of the
	/// bootstrap tests.
	static let testCasesPath: String = Utilities.getCurrentFolder() + "/ASTDumps-Swift-5.5/Test cases/"
	static let kotlinTestCasesPath: String = Utilities.getCurrentFolder() + "/Test cases/"

	static let libraryASTDumpFilePath = "ASTDumps-Swift-5.5/gryphon/GryphonTemplatesLibrary.swiftASTDump"

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
		"switches",
	]
}
